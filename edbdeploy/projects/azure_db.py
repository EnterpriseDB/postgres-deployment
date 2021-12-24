import getpass

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..project import Project
from ..spec.aws_rds import TPROCC_GUC


class AzureDBProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(AzureDBProject, self).__init__('azure-db', name, env, bin_path)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)
        self._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()

    def hook_pre_create(self):
        # Hook function called by Project.configure()
        msg = "Set Initial Database Super User Password:"
        self.postgres_passwd = getpass.getpass(msg)

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
        pem = env.cloud_spec['pem_server']
        hammerdb = env.cloud_spec['hammerdb_server']
        guc = TPROCC_GUC

        self.terraform_vars.update({
            'azure_offer': os['offer'],
            'azure_publisher': os['publisher'],
            'azure_sku': os['sku'],
            'azuredb_passwd': self.postgres_passwd,
            'azuredb_sku': pg['sku'],
            'azure_region': env.azure_region,
            'guc_effective_cache_size': guc[env.shirt]['effective_cache_size'],
            'guc_max_wal_size': guc[env.shirt]['max_wal_size'],
            'pg_version': env.postgres_version,
        })
        self.terraform_vars['postgres_server'].update({
            'count': ra['pg_count'],
            'size': pg['size'],
            'sku': pg['sku'],
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
