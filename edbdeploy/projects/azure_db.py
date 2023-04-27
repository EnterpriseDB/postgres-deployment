from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..project import Project
from ..spec.azure_db import TPROCC_GUC
from ..password import get_password, random_password, save_password
from ..render import build_ansible_inventory

class AzureDBProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(AzureDBProject, self).__init__('azure-db', name, env, bin_path)

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


    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        pass

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._dbaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for Azure Database provisioning
        """

        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        guc = TPROCC_GUC

        self.terraform_vars.update({
            'azure_offer': os['offer'],
            'azure_publisher': os['publisher'],
            'azure_sku': os['sku'],
            'azuredb_passwd': get_password(self.project_path, 'postgres'),
            'azuredb_sku': pg['sku'],
            'azure_region': env.azure_region,
            'guc_effective_cache_size': guc[env.shirt]['effective_cache_size'],
            'guc_max_wal_size': guc[env.shirt]['max_wal_size'],
            'pg_version': env.postgres_version,
            'rocky': True if env.operating_system == 'RockyLinux8' else False
        })
        self.terraform_vars['postgres_server'].update({
            'instance_type': pg['sku'],
            'count': 0,
            'size': pg['size'],
        })

        # set variables for use with edbterraform
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
                # set variables for use with edbterraform
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
        # Setup cloudsql
        settings = list()
        settings.extend(self.database_settings(env))
        databases = dict({
            "postgres": {
                'public_access': True,
                'region': self.terraform_vars['azure_region'],
                'engine': "postgres",
                'engine_version': env.postgres_version,
                'dbname': 'dbname',
                'instance_type': pg['sku'],
                'volume': {
                    'size_gb': pg['size'],
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
                    'replication_type': self.terraform_vars['replication_type'] if self.terraform_vars.get('replication_type') else 'unset',
                    'pooler_type': self.terraform_vars['pooler_type'] if self.terraform_vars.get('pooler_type') else 'pgbouncer',
                    'pooler_local': self.terraform_vars.get('pooler_local', False),
                }
            },
        })
        self.terraform_vars[self.cloud_provider]['databases'] = databases

        azure_cli = CloudCli(self.cloud_provider, bin_path=self.cloud_tools_bin_path)
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
        self.terraform_vars['created_by'] = azure_cli.cli.get_caller_info()
        # ports needed
        self.terraform_vars['service_ports'], self.terraform_vars['region_ports'] = super()._get_default_ports()
        self.terraform_vars['image'] = dict({
            'offer': os['offer'].lower(),
            # Azure's plans are case sensitive and will cause terraform to fail.
            # Error:
            #   Code="VMMarketplaceInvalidInput" Message="Unable to deploy from the Marketplace image
            #   or a custom image sourced from Marketplace image. The part number in the purchase information
            #   for VM '/subscriptions/resourceGroups/...' is not as expected. 
            #   Beware that the Plan object's properties are case-sensitive. 
            # There are cases where the shell vs powershell cli give back different results as well:
            # ex: Redhat vs redhat
            'publisher': os['publisher'].lower(),
            'sku': os['sku'],
            'ssh_user': self.terraform_vars['ssh_user'],
            'version': azure_cli.cli.check_image_availability(
                self.terraform_vars['azure_publisher'],
                self.terraform_vars['azure_offer'],
                self.terraform_vars['azure_sku'],
                env.azure_region,
            ).get('version')
        })
        self.terraform_vars['region'] = self.terraform_vars['azure_region']
        # create a set of zones from each machine's instance type and region availability zone  
        instance_types: set = {
            values['instance_type'] for key, values in self.terraform_vars.items()
            if any(substr in key for substr in ['dbt2_client', 'dbt2_driver', '_server']) and
            isinstance(values, dict) and
            values.get('count', 0) >= 1
            and values.get('instance_type')
        }
        filtered_zones: set = {zone for instance in instance_types for zone in azure_cli.check_instance_type_availability(instance, self.terraform_vars['azure_region'])}
        self.terraform_vars['zones'] = list(filtered_zones)

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        with AM("Checking instances availability in region %s"
                % self.terraform_vars['azure_region']):
            cloud_cli.cli.check_instances_availability(
                self.name,
                self.terraform_vars['azure_region'],
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
            {'name': 'work_mem', 'value': 65536},
        ]
