import json
import os
import re
import shutil
import sys

from ..action import ActionManager as AM
from ..ansible import AnsibleCli
from ..cloud import CloudCli
from ..errors import ProjectError
from ..project import Project


class AzurePOTProject(Project):

    ansible_collection_name = 'edb_devops.edb_postgres:3.3.2'
    aws_collection_name = 'community.aws:1.4.0'

    def __init__(self, name, env, bin_path=None):
        super(AzurePOTProject, self).__init__('azure-pot', name, env, bin_path)
        # Use Azure terraform code
        self.terraform_path = os.path.join(self.terraform_share_path, 'azure')
        # POT only attributes
        self.ansible_pot_role = os.path.join(self.ansible_share_path, 'roles')
        self.custom_ssh_keys = {}
        # Force PG version to 13 in POT env.
        self.postgres_version = '13'
        self.reference_architecture_code = "EDB-RA-2"
        self.operating_system = "CentOS8"

    def configure(self, env):
        # Overload Project.configure()
        # Load specifications
        env.cloud_spec = self._load_cloud_specs(env)
        # Copy the PoT role in ansible project directory
        ansible_roles_path = os.path.join(self.project_path, "roles")
        with AM("Copying PoT role code from into %s" % ansible_roles_path):
            try:
                shutil.copytree(self.ansible_pot_role, ansible_roles_path)
            except Exception as e:
                raise ProjectError(str(e))

        with AM("Creating ssh keys for project"):
            _os = self.operating_system
            ssh_user = env.cloud_spec['available_os'][_os]['ssh_user']
            self.ssh_key_gen(ssh_user, False)

        with AM("Creating customer ssh keys for project"):
            self.ssh_key_gen(self.name, True)

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
        # Overload Project._build_ansible_vars()
        """
        Build Ansible variables for the IaaS cloud vendors: aws, gcloud and
        azure.
        """
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)

        os_spec = env.cloud_spec['available_os'][self.operating_system]
        pg_spec = env.cloud_spec['postgres_server']

        self.ansible_vars = {
            'reference_architecture': self.reference_architecture_code,
            'cluster_name': self.name,
            'pg_type': env.postgres_type,
            'pg_version': self.postgres_version,
            'repo_username': edb_repo_username,
            'repo_password': edb_repo_password,
            'ssh_user': os_spec['ssh_user'],
            'ssh_priv_key': self.custom_ssh_keys[os_spec['ssh_user']]['ssh_priv_key'],  # noqa
            'email_id': env.email_id,
            'route53_access_key': env.route53_access_key,
            'route53_secret': env.route53_secret,
            'project': self.name,
            'public_key': self.custom_ssh_keys[self.name]['ssh_pub_key'],
        }

        # Add configuration for pg_data and pg_wal accordingly to the
        # number of additional volumes
        if pg_spec['additional_volumes']['count'] > 0:
            self.ansible_vars.update(dict(pg_data='/pgdata/pg_data'))
        if pg_spec['additional_volumes']['count'] > 1:
            self.ansible_vars.update(dict(pg_wal='/pgwal/pg_wal'))

    def _build_terraform_vars(self, env):
        # Overload Project._build_terraform_vars()
        """
        Build Terraform variable for Azure provisioning
        """
        ra = self.reference_architecture[self.reference_architecture_code]
        pg = env.cloud_spec['postgres_server']
        os_ = env.cloud_spec['available_os'][self.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']
        hammerdb = env.cloud_spec['hammerdb_server']

        self.terraform_vars = {
            'azure_offer': os_['offer'],
            'azure_publisher': os_['publisher'],
            'azure_sku': os_['sku'],
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

    def deploy(self, no_install_collection,
               pre_deploy_ansible=None,
               post_deploy_ansible=None,
               skip_main_playbook=False):

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )

        # Load ansible vars
        self._load_ansible_vars()

        if not no_install_collection:
            with AM("Installing Ansible collection %s" % self.ansible_collection_name):  # noqa
                ansible.install_collection(self.ansible_collection_name)
            with AM("Installing AWS collection %s" % self.aws_collection_name):  # noqa
                ansible.install_collection(self.aws_collection_name)

        # Building extra vars to pass to ansible because it's not safe to pass
        # the content of ansible_vars as it.
        extra_vars = dict(
            pg_type=self.ansible_vars['pg_type'],
            pg_version=self.ansible_vars['pg_version'],
            repo_username=self.ansible_vars['repo_username'],
            repo_password=self.ansible_vars['repo_password'],
            pass_dir=os.path.join(self.project_path, '.edbpass'),
            email_id=self.ansible_vars['email_id'],
            route53_access_key=self.ansible_vars['route53_access_key'],
            route53_secret=self.ansible_vars['route53_secret'],
            project=self.ansible_vars['project'],
            public_key=self.ansible_vars['public_key']
        )
        if self.ansible_vars.get('pg_data'):
            extra_vars.update(dict(
                pg_data=self.ansible_vars['pg_data']
            ))
        if self.ansible_vars.get('pg_wal'):
            extra_vars.update(dict(
                pg_wal=self.ansible_vars['pg_wal']
            ))

        if pre_deploy_ansible:
            with AM("Executing pre deploy playbook using Ansible"):
                ansible.run_playbook(
                    self.cloud,
                    self.ansible_vars['ssh_user'],
                    self.ansible_vars['ssh_priv_key'],
                    self.ansible_inventory,
                    pre_deploy_ansible.name,
                    json.dumps(extra_vars)
                )

        if not skip_main_playbook:
            self.update_state('ansible', 'DEPLOYING')
            with AM("Deploying components with Ansible"):
                ansible.run_playbook(
                    self.cloud,
                    self.ansible_vars['ssh_user'],
                    self.ansible_vars['ssh_priv_key'],
                    self.ansible_inventory,
                    self.ansible_playbook,
                    json.dumps(extra_vars)
                )
            self.update_state('ansible', 'DEPLOYED')

            with AM("Extracting data from the inventory file"):
                inventory_data = ansible.list_inventory(self.ansible_inventory)

        if post_deploy_ansible:
            with AM("Executing post deploy playbook using Ansible"):
                ansible.run_playbook(
                    self.cloud,
                    self.ansible_vars['ssh_user'],
                    self.ansible_vars['ssh_priv_key'],
                    self.ansible_inventory,
                    post_deploy_ansible.name,
                    json.dumps(extra_vars)
                )

        if not skip_main_playbook:
            # Display inventory informations
            self.display_inventory(inventory_data)

    def display_inventory(self, inventory_data):
        # Overload Project.display_inventory()
        if not self.ansible_vars:
            self._load_ansible_vars()

        def _p(s):
            sys.stdout.write(s)

        sys.stdout.flush()
        _p("\n")

        # Display PEM server informations
        if 'pemserver' in inventory_data['all']['children']:
            if self.ansible_vars['pg_type'] == 'EPAS':
                pem_user = 'enterprisedb'
            else:
                pem_user = 'postgres'
            pem_name = inventory_data['pemserver']['hosts'][0]
            pem_hostvars = inventory_data['_meta']['hostvars'][pem_name]

            # In PoT PEM server is client server
            client_login_ip = pem_hostvars['ansible_host']
            client_private_ip = pem_hostvars['private_ip']
            se_login_user = self.ansible_vars['ssh_user']

            with open(
                os.path.join(
                    self.project_path, '.edbpass', '%s_pass' % pem_user
                )
            ) as f:
                pem_password = f.read()

            _p(
                "PEM Server: https://%spem.edbpov.io:8443/pem\n"
                % self.name
            )
            _p("PEM User: %s\n" % pem_user)
            _p("PEM Password: %s\n" % pem_password)

        # Build the nodes table
        rows = []
        for name, vars in inventory_data['_meta']['hostvars'].items():
            if name != pem_name:
                rows.append([
                    name,
                    vars['ansible_host'],
                    self.ansible_vars['ssh_user'],
                    vars['private_ip'],
                    self.name
                ])
        rows.append([
            'client',
            client_login_ip,
            se_login_user,
            client_private_ip,
            self.name
        ])

        Project.display_table(
            ['Name', 'Login IP Address', 'SE Login User',
             'Internal IP Address', 'Login User'],
            rows
        )

    def _copy_ansible_playbook(self):
        # Overload Project._copy_ansible_playbook()
        """
        Copy reference architecture Ansible playbook into project directory.
        """
        with AM(
            "Copying Ansible playbook file into %s" % self.ansible_playbook
        ):
            shutil.copy(
                os.path.join(self.ansible_share_path, "PoT-EDB-RA-2.yml"),
                self.ansible_playbook
            )
