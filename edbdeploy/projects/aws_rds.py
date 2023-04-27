import re

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..password import get_password, random_password, save_password
from ..project import Project
from ..spec.aws_rds import TPROCC_GUC
from ..render import build_ansible_inventory
from collections import ChainMap


class AWSRDSProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(AWSRDSProject, self).__init__('aws-rds', name, env, bin_path)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Transform Terraform templates
        # Build a random master user password
        with AM("Building master user password"):
            save_password(self.project_path, 'postgres', random_password())

        # Build the vars files for Terraform and Ansible
        super()._build_terraform_files()
        super()._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        super()._copy_ansible_playbook()
        # Check Cloud Instance type and Image availability.
        self._check_instance_image(env)

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        region = self.terraform_vars['aws_region']
        with AM("Checking instances availability in region %s" % region):
            cloud_cli.cli.check_instances_availability(region)

    def hook_inventory_yml(self, vars):
        # Hook function called by Project.provision()
        with AM("Generating the inventory.yml file"):
            template_vars = dict()
            template_vars['vars'] = vars
            template_vars['servers'] = super()._get_terraform_instances()
            build_ansible_inventory(
                self.project_path,
                vars=template_vars
            )
    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._dbaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for AWS RDS provisioning
        """

        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        ra = self.reference_architecture[env.reference_architecture]
        os = env.cloud_spec['available_os'][env.operating_system]
        pg = env.cloud_spec['postgres_server']
        guc = TPROCC_GUC

        self.terraform_vars.update({
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os['image'],
            'aws_region': env.aws_region,
            'guc_effective_cache_size': guc[env.shirt]['effective_cache_size'],
            'guc_max_wal_size': guc[env.shirt]['max_wal_size'],
            'guc_shared_buffers': guc[env.shirt]['shared_buffers'],
            'pg_password': get_password(self.project_path, 'postgres'),
            'pg_version': env.postgres_version,
        })
        self.terraform_vars['postgres_server'].update({
            'instance_type': pg.get('instance_type', ''),
            'volume': pg.get('volume', {}),
            'count': 0 # do not create since it will be an rds/aurora instance
        })

        # set variables for use with edbterraform
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
        # Setup RDS
        settings = list()
        settings.extend(self.database_settings(env))
        databases = dict({ 
            "postgres": {
                'region': self.terraform_vars['aws_region'],
                'engine': "postgres",
                'engine_version': env.postgres_version,
                'dbname': 'postgres',
                'instance_type': self.terraform_vars['postgres_server']['instance_type'],
                'volume': {
                    'size_gb': self.terraform_vars['postgres_server']['volume'].get('size'),
                    'type': self.terraform_vars['postgres_server']['volume'].get('type'),
                    'iops': self.terraform_vars['postgres_server']['volume'].get('iops'),
                    'encrypted': False,
                },
                'username':'postgres',
                'password': get_password(self.project_path, 'postgres'),
                'settings': settings,
                'port': 5432,
                'tags': {
                    'type': 'postgres_server',
                    'priority': 0,
                    'index': 0,
                    'postgres_group': 'postgres_server',
                    'replication_type': self.terraform_vars.get('replication_type'),
                    'pooler_type': self.terraform_vars.get('pooler_type', 'pgbouncer'),
                    'pooler_local': self.terraform_vars.get('pooler_local', False),
                }
            },
        })
        self.terraform_vars[self.cloud_provider]['databases'] = databases

        aws_cli = CloudCli(self.cloud_provider, bin_path=self.cloud_tools_bin_path)
        self.terraform_vars['created_by'] = aws_cli.cli.get_caller_info()
        self.terraform_vars['service_ports'], self.terraform_vars['region_ports'] = self._get_default_ports()
        self.terraform_vars['image'] = dict({
            'name': self.terraform_vars['aws_image'],
            'owner': aws_cli.cli.get_image_owner(self.terraform_vars['aws_image'], self.terraform_vars['aws_region']),
            'ssh_user': self.terraform_vars['ssh_user'],
        })
        self.terraform_vars['region'] = self.terraform_vars['aws_region']
        # create a set of zones from each machine's instance type and region availability zone  
        instance_types: set = {
            values['instance_type'] for key, values in self.terraform_vars.items()
            if any(substr in key for substr in ['dbt2_client', 'dbt2_driver', '_server']) and
            isinstance(values, dict) and
            values.get('count', 0) >= 1 and 
            values.get('instance_type') and
            key != 'postgres_server' # skip postgres server since rds is set above
        }
        filtered_zones: set = {zone for instance in instance_types for zone in aws_cli.check_instance_type_availability(instance, self.terraform_vars['aws_region'])}
        filtered_zones.intersection_update(aws_cli.cli.get_available_zones(self.terraform_vars['aws_region']))
        self.terraform_vars['zones'] = list(filtered_zones)

        self.overrides(env)

    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        """
        Check AWS RDS DB class instance, EC2 instance type and EC2 image id
        availability in specified region.
        """
        # Instanciate new CloudClis
        cloud_cli = CloudCli(env.cloud, bin_path=self.cloud_tools_bin_path)
        aws_cli = CloudCli('aws', bin_path=self.cloud_tools_bin_path)

        # Node types list available for this Cloud vendor
        node_types = ['postgres_server', 'pem_server', 'hammerdb_server']

        # Check instance type and image availability
        if not self.terraform_vars['aws_ami_id']:
            pattern = re.compile(r"^db\.")
            for instance_type in self._get_instance_types(node_types):
                if pattern.match(instance_type):
                    with AM(
                        "Checking DB class type %s availability in %s"
                        % (instance_type, env.aws_region)
                    ):
                        cloud_cli.check_instance_type_availability(
                            instance_type, env.aws_region
                        )
                else:
                    with AM(
                        "Checking instance type %s availability in %s"
                        % (instance_type, env.aws_region)
                    ):
                        aws_cli.check_instance_type_availability(
                            instance_type, env.aws_region
                        )

            # Check availability of image in target region and get its ID
            with AM(
                "Checking image '%s' availability in %s"
                % (self.terraform_vars['aws_image'], env.aws_region)
            ):
                aws_ami_id = aws_cli.cli.get_image_id(
                    self.terraform_vars['aws_image'], env.aws_region
                )
                if not aws_ami_id:
                    raise ProjectError(
                        "Unable to get Image Id for image %s in region %s"
                        % (self.terraform_vars['aws_image'], env.aws_region)
                    )
            with AM("Updating Terraform vars with the AMI id %s" % aws_ami_id):
                self.terraform_vars['aws_ami_id'] = aws_ami_id
                super()._save_terraform_vars()

    def _get_default_ports(self):
        '''
        Override Project._get_default_ports()
        Get the default needed ports for most reference architectures.
        Returned as a tuple of (service_ports, region_ports) for use with edb-terraform
        '''
        service_ports = list()
        service_ports.append({'port': 22, 'protocol': 'tcp', 'description': 'SSH default'})
        service_ports.append({'port': 80, 'protocol': 'tcp', 'description': 'http'})
        service_ports.append({'port': 8443, 'protocol': 'tcp', 'description': 'tcp'})
        service_ports.append({'port': 5432, 'protocol': 'tcp', 'description': 'tcp'})
        service_ports.append({'port': 5444, 'protocol': 'tcp', 'description': 'tcp'})
        service_ports.extend([{'port': port, 'protocol': 'tcp', 'description': 'tcp'} for port in range(7800,7811)])
        service_ports.append({'port': 30000, 'protocol': 'tcp', 'description': 'dbt2 client'})
        region_ports = list()
        region_ports.append({'protocol': 'icmp', 'description': 'regional ping'})

        return service_ports, region_ports

    def overrides(self, env):
        pass

    def database_settings(self, env):
        guc = TPROCC_GUC
        return [
            {'name': 'checkpoint_timeout', 'value': 900 },
            {'name': 'effective_cache_size', 'value': guc[env.shirt]['effective_cache_size']},
            {'name': 'max_connections', 'value': 300},
            {'name': 'max_wal_size', 'value': guc[env.shirt]['max_wal_size']},
            {'name': 'shared_buffers', 'value': guc[env.shirt]['shared_buffers']},
            {'name': 'work_mem', 'value': 65536},
        ]
