from ..action import ActionManager as AM
from ..project import Project
from ..password import get_password, random_password, save_password
from ..render import build_ansible_inventory
from ..spec.gcloud_sql import TPROCC_GUC
from ..cloud import CloudCli

class GCloudSQLProject(Project):
    def __init__(self, name, env, bin_path=None, using_edbterraform=True):
        super(GCloudSQLProject, self).__init__(
            'gcloud-sql', name, env, bin_path, using_edbterraform
        )

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

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._dbaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for GCloud SQL provisioning
        """      
        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        # Configure project specific terraform variables
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        guc = TPROCC_GUC

        self.terraform_vars.update({
            'gcloud_image': os['image'],
            'gcloud_region': env.gcloud_region,
            'gcloud_credentials': env.gcloud_credentials.name if env.gcloud_credentials else None,
            'gcloud_project_id': env.gcloud_project_id,
            'guc_effective_cache_size': guc[env.shirt]['effective_cache_size'],
            'guc_max_wal_size': guc[env.shirt]['max_wal_size'],
            'guc_shared_buffers': guc[env.shirt]['shared_buffers'],
            'pg_password': get_password(self.project_path, 'postgres'),
            'pg_version': env.postgres_version,
        })
        self.terraform_vars['postgres_server'].update({
            'instance_type': pg.get('instance_type', ''),
            'volume': pg.get('volume', {}),
            'count': 0 # do not create since it will be an cloudsql instance
        })

        # set variables for use with edbterraform
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
        # Setup cloudsql
        settings = list()
        settings.extend(self.database_settings(env))
        databases = dict({
            "postgres": {
                'public_access': True,
                'region': self.terraform_vars['gcloud_region'],
                'engine': "postgres",
                'engine_version': env.postgres_version,
                'dbname': 'dbname',
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
                    'priority': 1,
                    'index': 1,
                    'postgres_group': 'postgres_server',
                    'replication_type': self.terraform_vars['replication_type'] if self.terraform_vars.get('replication_type') else 'unset',
                    'pooler_type': self.terraform_vars['pooler_type'] if self.terraform_vars.get('pooler_type') else 'pgbouncer',
                    'pooler_local': self.terraform_vars.get('pooler_local', False),
                }
            },
        })
        self.terraform_vars[self.cloud_provider]['databases'] = databases

        gcloud_cli = CloudCli(self.cloud_provider, bin_path=self.cloud_tools_bin_path)
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
        self.terraform_vars['created_by'] = gcloud_cli.cli.get_caller_info()
        # ports needed
        self.terraform_vars['service_ports'], self.terraform_vars['region_ports'] = super()._get_default_ports()
        self.terraform_vars['image'] = dict({
            'name': self.terraform_vars['gcloud_image'],
            'ssh_user': self.terraform_vars['ssh_user'],
        })
        self.terraform_vars['region'] = self.terraform_vars['gcloud_region']
        # create a set of zones from each machine's instance type and region availability zone  
        instance_types: set = {
            values['instance_type'] for key, values in self.terraform_vars.items()
            if any(substr in key for substr in ['dbt2_client', 'dbt2_driver', '_server']) and
            isinstance(values, dict) and
            values.get('count', 0) >= 1 and 
            values.get('instance_type') and
            key != 'postgres_server' # skip postgres server since sql is set above
        }
        filtered_zones: set = {zone for instance in instance_types for zone in gcloud_cli.check_instance_type_availability(instance, self.terraform_vars['gcloud_region'])}
        filtered_zones.intersection_update(gcloud_cli.cli.get_available_zones(self.terraform_vars['gcloud_region']))
        self.terraform_vars['zones'] = list(filtered_zones)
        databases['postgres']['zone'] = self.terraform_vars['zones'][-1]


    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        pass

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        with AM("Checking instances availability in region %s"
                % self.terraform_vars['gcloud_region']):
            cloud_cli.cli.check_instances_availability(
                self.name,
                self.terraform_vars['gcloud_region'],
                # Total number of nodes
                (self.terraform_vars['postgres_server']['count']
                 + self.terraform_vars['pem_server']['count'])
            )

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
