import re

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..password import get_password, random_password, save_password
from ..project import Project
from ..spec.aws_rds import TPROCC_GUC


class AWSRDSProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(AWSRDSProject, self).__init__('aws-rds', name, env, bin_path)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build a random master user password
        with AM("Building master user password"):
            save_password(self.project_path, 'postgres', random_password())

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
            'instance_type': pg['instance_type'],
            'volume': pg['volume'],
        })

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
                # Useless variable for Terraform
                del(self.terraform_vars['aws_image'])
                self.terraform_vars['aws_ami_id'] = aws_ami_id
                self._save_terraform_vars()
