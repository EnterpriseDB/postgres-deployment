import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..project import Project
from .. import __edb_ansible_version__
from ..render import build_config_yml, build_inventory_yml


class AzurePOTProject(Project):

    ansible_collection_name = 'edb_devops.edb_postgres:>=%s,<4.0.0' % __edb_ansible_version__  # noqa
    aws_collection_name = 'community.aws:1.4.0'

    def __init__(self, name, env, bin_path=None):
        super(AzurePOTProject, self).__init__('azure-pot', name, env, bin_path)
        # Use Azure terraform code
        self.terraform_path = os.path.join(self.terraform_share_path, 'azure')
        # Route53 entry removal playbook
        self.ansible_route53_remove = os.path.join(self.ansible_share_path, 'POT-Remove-Project-Route53.yml')
        # POT only attributes
        self.ansible_pot_role = os.path.join(self.ansible_share_path, 'roles')
        # TPAexec hooks path
        self.tpaexec_pot_hooks = os.path.join(self.tpaexec_share_path, 'hooks')
        self.custom_ssh_keys = {}
        # Force PG version to 14 in POT env.
        self.postgres_version = '14'
        self.operating_system = "RockyLinux8"

    def configure(self, env):
        self.pot_configure(env)

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

    def hook_config_yml(self, vars):
        # Hook function called by Project.provision()
        with AM("Generating the config.yml file"):
            build_config_yml(
                os.path.join(self.project_path, 'config.yml'),
                os.path.join(self.project_path, 'servers.yml'),
                vars=vars
            )

    def _build_ansible_vars(self, env):
        self.pot_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for Azure provisioning
        """
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os_ = env.cloud_spec['available_os'][self.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']
        dbt2_client = env.cloud_spec['dbt2_client']
        dbt2_driver = env.cloud_spec['dbt2_driver']
        hammerdb = env.cloud_spec['hammerdb_server']
        bdr = env.cloud_spec['bdr_server']
        bdr_witness = env.cloud_spec['bdr_witness_server']

        self.terraform_vars = {
            'azure_offer': os_['offer'],
            'azure_publisher': os_['publisher'],
            'azure_sku': os_['sku'],
            'azure_region': env.azure_region,
            'barman': ra['barman'],
            'barman_server': {
                'count': ra['barman_server_count'],
                'instance_type': barman['instance_type'],
                'volume': barman['volume'],
                'additional_volumes': barman['additional_volumes'],
            },
            'cluster_name': self.name,
            'dbt2': ra['dbt2'],
            'dbt2_client': {
                'count': ra['dbt2_client_count'],
                'instance_type': dbt2_client['instance_type'],
                'volume': dbt2_client['volume'],
            },
            'dbt2_driver': {
                'count': ra['dbt2_driver_count'],
                'instance_type': dbt2_driver['instance_type'],
                'volume': dbt2_driver['volume'],
            },
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
            'bdr_server': {
                'count': ra['bdr_server_count'],
                'instance_type': bdr['instance_type'],
                'volume': bdr['volume'],
                'additional_volumes': bdr['additional_volumes'],
            },
            'bdr_witness_server': {
                'count': ra['bdr_witness_count'],
                'instance_type': bdr_witness['instance_type'],
                'volume': bdr_witness['volume'],
            },
            'pg_type': env.postgres_type,
            'replication_type': ra['replication_type'],
            'ssh_priv_key': self.custom_ssh_keys[os_['ssh_user']]['ssh_priv_key'],  # noqa
            'ssh_pub_key': self.custom_ssh_keys[os_['ssh_user']]['ssh_pub_key'],  # noqa 
            'ssh_user': os_['ssh_user'],
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

    def provision(self, env):
        self.pot_provision(env)

    def deploy(self, no_install_collection,
               pre_deploy_ansible=None,
               post_deploy_ansible=None,
               skip_main_playbook=False,
               disable_pipelining=False):
        self.pot_deploy(
            no_install_collection,
            pre_deploy_ansible,
            post_deploy_ansible,
            skip_main_playbook,
            disable_pipelining
        )

    def display_inventory(self, inventory_data):
        self.pot_display_inventory(inventory_data)

    def destroy(self):
        self.pot_destroy()
