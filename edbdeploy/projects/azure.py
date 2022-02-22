import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..project import Project
from ..render import build_inventory_yml


class AzureProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(AzureProject, self).__init__('azure', name, env, bin_path)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)
        self._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()
        # Check Cloud Instance type and Image availability.
        self._check_instance_image(env)

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        with AM("Checking instances availability"):
            cloud_cli.cli.check_instances_availability(self.name)

    def hook_inventory_yml(self, vars):
        # Hook function called by Project.provision()
        with AM("Generating the inventory.yml file"):
            build_inventory_yml(
                self.ansible_inventory,
                os.path.join(self.project_path, 'servers.yml'),
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
