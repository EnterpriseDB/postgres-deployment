import os

from ..action import ActionManager as AM
from ..cloud import CloudCli
from ..errors import ProjectError
from ..project import Project


class AWSPOTProject(Project):

    ansible_collection_name = 'edb_devops.edb_postgres:3.4.0'
    aws_collection_name = 'community.aws:1.4.0'

    def __init__(self, name, env, bin_path=None):
        super(AWSPOTProject, self).__init__('aws-pot', name, env, bin_path)
        # Use AWS terraform code
        self.terraform_path = os.path.join(self.terraform_share_path, 'aws')
        # POT only attributes
        self.ansible_pot_role = os.path.join(self.ansible_share_path, 'roles')
        self.custom_ssh_keys = {}
        # Force PG version to 13 in POT env.
        self.postgres_version = '13'
        self.reference_architecture_code = "EDB-RA-2"
        self.operating_system = "CentOS8"

    def configure(self, env):
        self.pot_configure(env)

    def hook_instances_availability(self, cloud_cli):
        # Hook function called by Project.provision()
        region = self.terraform_vars['aws_region']
        with AM("Checking instances availability in region %s" % region):
            cloud_cli.cli.check_instances_availability(region)

    def _build_ansible_vars(self, env):
        self.pot_build_ansible_vars(env)

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for AWS provisioning
        """
        ra = self.reference_architecture[self.reference_architecture_code]
        pg = env.cloud_spec['postgres_server']
        os_ = env.cloud_spec['available_os'][self.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']
        hammerdb = env.cloud_spec['hammerdb_server']

        self.terraform_vars = {
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os_['image'],
            'aws_region': env.aws_region,
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
            'pg_version': self.postgres_version,
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
            'ssh_priv_key': self.custom_ssh_keys[os_['ssh_user']]['ssh_priv_key'],  # noqa
            'ssh_pub_key': self.custom_ssh_keys[os_['ssh_user']]['ssh_pub_key'],  # noqa
            'ssh_user': os_['ssh_user'],
        }

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

    def deploy(self, no_install_collection,
               pre_deploy_ansible=None,
               post_deploy_ansible=None,
               skip_main_playbook=False):
        self.pot_deploy(
            no_install_collection,
            pre_deploy_ansible,
            post_deploy_ansible,
            skip_main_playbook
        )

    def display_inventory(self, inventory_data):
        self.pot_display_inventory(inventory_data)

    def _copy_ansible_playbook(self):
        self.pot_copy_ansible_playbook()
