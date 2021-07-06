from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..project import Project


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

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        self._iaas_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for Azure provisioning
        """
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']
        hammerdb = env.cloud_spec['hammerdb_server']

        self.terraform_vars = {
            'azure_offer': os['offer'],
            'azure_publisher': os['publisher'],
            'azure_sku': os['sku'],
            'azure_region': env.azure_region,
            'barman': ra['barman'],
            'barman_server': {
                'count': 1 if ra['barman_server'] else 0,
                'instance_type': barman['instance_type'],
                'volume': barman['volume'],
                'additional_volumes': barman['additional_volumes'],
            },
            'cluster_name': self.name,
            'hammerdb': ra['hammerdb'],
            'hammerdb_server': {
                'count': 1 if ra['hammerdb_server'] else 0,
                'instance_type': hammerdb['instance_type'],
                'volume': hammerdb['volume'],
            },
            'pem_server': {
                'count': 1 if ra['pem_server'] else 0,
                'instance_type': pem['instance_type'],
                'volume': pem['volume'],
            },
            'pg_version': env.postgres_version,
            'pooler_local': ra['pooler_local'],
            'pooler_server': {
                'count': ra['pooler_count'],
                'instance_type': pooler['instance_type'],
                'volume': pooler['volume'],
            },
            'pooler_type': ra['pooler_type'],
            'postgres_server': {
                'count': ra['pg_count'],
                'instance_type': pg['instance_type'],
                'volume': pg['volume'],
                'additional_volumes': pg['additional_volumes'],
            },
            'pg_type': env.postgres_type,
            'replication_type': ra['replication_type'],
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

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
            cloud_cli.cli.check_image_availability(
                self.terraform_vars['azure_publisher'],
                self.terraform_vars['azure_offer'],
                self.terraform_vars['azure_sku'],
                env.azure_region
            )
