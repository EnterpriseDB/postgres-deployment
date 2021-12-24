import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..project import Project
from ..render import build_inventory_yml


class AWSProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(AWSProject, self).__init__('aws', name, env, bin_path)

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
        region = self.terraform_vars['aws_region']
        with AM("Checking instances availability in region %s" % region):
            cloud_cli.cli.check_instances_availability(region)

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
        Build Terraform variable for AWS provisioning
        """

        # Initialize terraform variables with common values
        self._init_terraform_vars(env)

        # Configure project specific terraform variables
        os = env.cloud_spec['available_os'][env.operating_system]
        pg = env.cloud_spec['postgres_server']

        self.terraform_vars.update({
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os['image'],
            'aws_region': env.aws_region,
        })
        self.terraform_vars['postgres_server'].update({
            'volume': pg['volume'],
            'additional_volumes': pg['additional_volumes'],
            'instance_type': pg['instance_type'],
        })

    def _check_instance_image(self, env):
        # Overload Project._check_instance_image()
        """
        Check AWS instance type and image id availability in specified region.
        """
        # Instanciate a new CloudCli
        cloud_cli = CloudCli(env.cloud, bin_path=self.cloud_tools_bin_path)

        # Node types list available for this Cloud vendor
        node_types = ['postgres_server', 'pem_server', 'hammerdb_server',
                      'barman_server', 'pooler_server']

        # Check instance type and image availability
        if not self.terraform_vars['aws_ami_id']:
            for instance_type in self._get_instance_types(node_types):
                with AM(
                    "Checking instance type %s availability in %s"
                    % (instance_type, env.aws_region)
                ):
                    cloud_cli.check_instance_type_availability(
                        instance_type, env.aws_region
                    )

            # Check availability of image in target region and get its ID
            with AM(
                "Checking image '%s' availability in %s"
                % (self.terraform_vars['aws_image'], env.aws_region)
            ):
                aws_ami_id = cloud_cli.cli.get_image_id(
                    self.terraform_vars['aws_image'], env.aws_region
                )
                if not aws_ami_id:
                    raise ProjectError(
                        "Unable to get Image Id for image %s in region %s"
                        % (self.terraform_vars['aws_image'], env.aws_region)
                    )
            with AM("Updating Terraform vars with the AMI id %s" % aws_ami_id):
                # Useless variable for Terraform
                del(self.terraform_vars['aws_image'])
                self.terraform_vars['aws_ami_id'] = aws_ami_id
                self._save_terraform_vars()
