import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..project import Project
from ..render import build_inventory_yml


class GCloudProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(GCloudProject, self).__init__('gcloud', name, env, bin_path)

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
        region = self.terraform_vars['gcloud_region']
        with AM("Checking instances availability in region %s" % region):
            cloud_cli.cli.check_instances_availability(
                self.name,
                region,
                # Total number of nodes
                (self.terraform_vars['postgres_server']['count']
                 + self.terraform_vars['barman_server']['count']
                 + self.terraform_vars['pem_server']['count']
                 + self.terraform_vars['pooler_server']['count'])
            )

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
        Build Terraform variable for GCloud provisioning
        """
        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        # Configure project specific terraform variables
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']
        hammerdb = env.cloud_spec['hammerdb_server']
        bdr = env.cloud_spec['bdr_server']
        bdr_witness = env.cloud_spec['bdr_witness_server']

        self.terraform_vars.update({
            'gcloud_image': os['image'],
            'gcloud_region': env.gcloud_region,
            'gcloud_credentials': env.gcloud_credentials.name,
            'gcloud_project_id': env.gcloud_project_id,
        })
        self.terraform_vars['postgres_server'].update({
            'additional_volumes': pg['additional_volumes'],
            'instance_type': pg['instance_type'],
            'volume': pg['volume'],
        })

    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        """
        Check GCloud instance type and image id availability in specified
        region.
        """
        # Instanciate a new CloudCli
        cloud_cli = CloudCli(env.cloud, bin_path=self.cloud_tools_bin_path)

        # Build a list of instance_type accordingly to the specs
        node_types = ['postgres_server', 'pem_server', 'hammerdb_server',
                      'barman_server', 'pooler_server']

        # Check instance type and image availability
        for instance_type in self._get_instance_types(node_types):
            with AM(
                "Checking instance type %s availability in %s"
                % (instance_type, env.gcloud_region)
            ):
                cloud_cli.check_instance_type_availability(
                    instance_type, env.gcloud_region
                )
        # Check availability of the image
        with AM(
            "Checking image %s availability"
            % self.terraform_vars['gcloud_image']
        ):
            cloud_cli.cli.check_image_availability(
                self.terraform_vars['gcloud_image']
            )
