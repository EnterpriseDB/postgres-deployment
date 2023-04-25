import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..project import Project
from ..render import build_inventory_yml, build_ansible_inventory


class AzureProject(Project):
    def __init__(self, name, env, bin_path=None, using_edbterraform=True):
        super(AzureProject, self).__init__('azure', name, env, bin_path, using_edbterraform)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        ######################################################
        # Build the vars files for Terraform and Ansible
        # _build_terraform_vars override below
        super()._build_terraform_files()
        ######################################################
        super()._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        super()._copy_ansible_playbook()
        # Check Cloud Instance type and Image availability.
        self._check_instance_image(env)

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        with AM("Checking instances availability"):
            cloud_cli.cli.check_instances_availability(self.name)

    def hook_inventory_yml(self, vars):
        # Hook function called by Project.provision()
        with AM("Generating the inventory.yml file"):
            if self.using_edbterraform:
                template_vars = dict()
                template_vars['vars'] = vars
                server_vars = super()._load_terraform_outputs()
                server_vars = server_vars.get('servers')
                template_vars['servers'] = server_vars.get('machines', {})
                build_ansible_inventory(
                    self.project_path,
                    vars=template_vars
                )
            else:
                build_inventory_yml(
                    self.ansible_inventory,
                    super()._get_servers_filepath(),
                    vars=vars
                )

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._iaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for Azure provisioning
        """
        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        # Configure project specific terraform variables
        os = env.cloud_spec['available_os'][env.operating_system]
        pg = env.cloud_spec['postgres_server']

        self.terraform_vars.update({
            'azure_offer': os['offer'],
            'azure_publisher': os['publisher'],
            'azure_sku': os['sku'],
            'azure_region': env.azure_region,
            'rocky': True if env.operating_system == 'RockyLinux8' else False
        })
        self.terraform_vars['postgres_server'].update({
            'volume': pg['volume'],
            'additional_volumes': pg['additional_volumes'],
            'instance_type': pg['instance_type'],
        })

        # set variables for use with edbterraform
        cloud_cli = CloudCli(self.cloud_provider, bin_path=self.cloud_tools_bin_path)
        if not self.terraform_vars.get(self.cloud_provider):
            self.terraform_vars[self.cloud_provider] = dict()
        self.terraform_vars['created_by'] = cloud_cli.cli.get_caller_info()
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
            'version': cloud_cli.cli.check_image_availability(
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
        filtered_zones: set = {zone for instance in instance_types for zone in cloud_cli.check_instance_type_availability(instance, self.terraform_vars['azure_region'])}
        self.terraform_vars['zones'] = list(filtered_zones)

    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        """
        Check Azure instance type and image id availability in specified
        region.
        """
        # Instanciate a new CloudCli
        cloud_cli = CloudCli(env.cloud, bin_path=self.cloud_tools_bin_path)

        # Node types list available for this Cloud vendor
        node_types = ['postgres_server', 'pem_server', 'hammerdb_server',
                      'barman_server', 'pooler_server']

        # Check instance type and image availability
        for instance_type in self._get_instance_types(node_types):
            with AM(
                "Checking instance type %s availability in %s"
                % (instance_type, env.azure_region)
            ):
                cloud_cli.check_instance_type_availability(
                    instance_type, env.azure_region
                )
        # Check availability of image in target region
        with AM(
            "Checking image %s:%s:%s availability in %s"
            % (
                self.terraform_vars['azure_publisher'],
                self.terraform_vars['azure_offer'],
                self.terraform_vars['azure_sku'],
                env.azure_region
              )
        ):
            image = cloud_cli.cli.check_image_availability(
                self.terraform_vars['azure_publisher'],
                self.terraform_vars['azure_offer'],
                self.terraform_vars['azure_sku'],
                env.azure_region
            )
        if env.operating_system == 'RockyLinux8':
            with AM("Accepting marketplace terms for this image offer"):
                cloud_cli.cli.accept_terms(
                    self.terraform_vars['azure_publisher'],
                    self.terraform_vars['azure_offer'],
                    self.terraform_vars['azure_sku'],
                    image['version'],
                )
