import errno
import json
import logging
import os
import re
import shutil
import sys
import stat
import time

from .cloud import CloudCli, AWSCli
from .terraform import TerraformCli
from .ansible import AnsibleCli
from .action import ActionManager as AM

class ProjectError(Exception):
    pass


class Project:

    projects_root_path = os.getenv(
        'EDB_DEPLOY_DIR',
        os.path.join(os.path.expanduser("~"), ".edb_deploy")
    )
    terraform_share_path = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        '..',
        'share',
        'terraform'
    )
    ansible_share_path = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        '..',
        'share',
        'ansible'
    )
    terraform_templates = ['variables.tf.template', 'tags.tf.template']
    reference_architecture_path = './lib/spec/reference_architecture.json'
    ansible_collection_name = 'edb_devops.edb_postgres'

    def __init__(self, cloud, name):
        self.name = name
        self.cloud = cloud
        self.project_path = os.path.join(
            self.projects_root_path,
            self.cloud,
            self.name
        )
        self.terraform_path = os.path.join(
            self.terraform_share_path,
            self.cloud
        )
        self.ssh_priv_key = os.path.join(self.project_path, 'ssh_priv_key')
        self.ssh_pub_key = os.path.join(self.project_path, 'ssh_pub_key')
        self.terraform_vars = None
        self.terraform_vars_file = os.path.join(
            self.project_path,
            'terraform_vars.json'
        )
        self.ansible_vars = None
        self.ansible_vars_file = os.path.join(
            self.project_path,
            'ansible_vars.json'
        )
        self.reference_architecture = None
        self.log_file = os.path.join(
            self.projects_root_path, "log", self.cloud, "%s.log" % self.name
        )
        self.terraform_plugin_cache_path = os.path.join(
            self.projects_root_path,
            '.terraform_plugin_cache'
        )
        self.ansible_playbook = os.path.join(self.project_path, 'playbook.yml')
        self.ansible_inventory = os.path.join(
            self.project_path,
            'inventory.yml'
        )

    def create_log_dir(self):
        try:
            os.makedirs(os.path.dirname(self.log_file))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise ProjectError(str(e))
        except Exception as e:
            raise ProjectError(str(e))

    def exists(self):
        return os.path.exists(self.project_path)

    def create(self):
        # Copy terraform code
        with AM("Copying Terraform code from into %s" % self.project_path):
            try:
                shutil.copytree(self.terraform_path, self.project_path)
            except Exception as e:
                raise ProjectError(str(e))

        # Create Terraform plugin cache
        with AM(
            "Creating Terraform plugin cache dir. %s"
            % self.terraform_plugin_cache_path
        ):
            try:
                os.makedirs(self.terraform_plugin_cache_path)
            except OSError as e:
                if e.errno != errno.EEXIST:
                    raise ProjectError(str(e))
            except Exception as e:
                raise ProjectError(str(e))

    def configure(self, env):
        # Copy SSH keys
        with AM("Copying SSH key pair into %s" % self.project_path):
            shutil.copy(env.ssh_priv_key.name, self.ssh_priv_key)
            shutil.copy(env.ssh_pub_key.name, self.ssh_pub_key)
            os.chmod(self.ssh_priv_key, stat.S_IREAD | stat.S_IWRITE)
            os.chmod(self.ssh_pub_key, stat.S_IREAD | stat.S_IWRITE)

        # Transform templates
        for template in self.terraform_templates:
            template_path = os.path.join(self.project_path, template)
            dest_path = os.path.join(
                self.project_path,
                os.path.splitext(template)[0]
            )
            with AM(
                "Generating file %s from template %s" % (dest_path, template)
            ):
                with open(template_path, 'r') as f:
                    with open(dest_path, 'w') as d:
                        for l in f.readlines():
                            d.write(l.replace("%PROJECT_NAME%", self.name))
                os.unlink(template_path)

        # Load spec file
        with AM("Loading the JSON spec. file %s" % env.spec_file.name):
            env.cloud_spec = self._load_spec_file(env.spec_file.name)
            logging.debug("env.cloud_specs=%s", env.cloud_spec)

        # Build the vars files for Terraform and Ansible
        with AM("Building Terraform vars file %s" % self.terraform_vars_file):
            self._build_terraform_vars(env)
            logging.debug("terraform_vars=%s", self.terraform_vars)
            # Save Terraform vars
            self._save_terraform_vars()

        with AM("Building Ansible vars file %s" % self.ansible_vars_file):
            self._build_ansible_vars(env)
            logging.debug("ansible_vars=%s", self.ansible_vars)
            # Save Ansible vars
            self._save_ansible_vars()

        with AM("Copying Ansible playbook file %s" % self.ansible_playbook):
            shutil.copy(
                os.path.join(
                    self.ansible_share_path,
                    "%s.yml" % self.ansible_vars['reference_architecture']
                ),
                self.ansible_playbook
            )

        # Instanciate a new CloudCli
        cloud_cli = CloudCli(env.cloud)

        # Check availability of instance types in target region
        instance_types = []
        node_types = ['postgres_server', 'pem_server', 'barman_server',
                      'pooler_server']
        for node_type in node_types:
            node = self.terraform_vars.get(node_type)
            if not node:
                continue
            if node['instance_type'] not in instance_types:
                instance_types.append(node['instance_type'])

        if env.cloud == 'aws' and not self.terraform_vars['aws_ami_id']:
            for instance_type in instance_types:
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
                % (self.terraform_vars['image'], env.aws_region)
            ):
                aws_ami_id = cloud_cli.cli.get_image_id(
                    self.terraform_vars['image'], env.aws_region
                )
                if not aws_ami_id:
                    raise ProjectError(
                        "Unable to get Image Id for image %s in region %s"
                        % (self.terraform_vars['image'], env.aws_region)
                    )
            with AM("Updating Terraform vars with the AMI id %s" % aws_ami_id):
                del(self.terraform_vars['image'])
                self.terraform_vars['aws_ami_id'] = aws_ami_id
                self._save_terraform_vars()

    def _load_spec_file(self, spec_file_path):
        try:
            with open(spec_file_path) as json_file:
                data = json.loads(json_file.read())
            return data
        except json.decoder.JSONDecodeError as e:
            msg = "Unable to load the JSON spec. file %s" % spec_file_path
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

    def _load_terraform_vars(self):
        try:
            with open(self.terraform_vars_file) as json_file:
                self.terraform_vars = json.loads(json_file.read())
        except json.decoder.JSONDecodeError as e:
            msg = ("Unable to load the Terraform vars file %s"
                   % self.terraform_vars_file)
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

    def _save_terraform_vars(self):
        try:
            with open(self.terraform_vars_file, "w") as json_file:
                json_file.write(json.dumps(self.terraform_vars, indent=2))
        except Exception as e:
            msg = ("Unable to save the Terraform vars file %s"
                    % self.terraform_vars_file)
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

    def _load_ansible_vars(self):
        try:
            with open(self.ansible_vars_file) as json_file:
                self.ansible_vars = json.loads(json_file.read())
        except json.decoder.JSONDecodeError as e:
            msg = ("Unable to load the Ansible vars file %s"
                   % self.ansible_vars_file)
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

    def _save_ansible_vars(self):
        try:
            with open(self.ansible_vars_file, "w") as json_file:
                json_file.write(json.dumps(self.ansible_vars, indent=2))
        except Exception as e:
            msg = ("Unable to save the Ansible vars file %s"
                    % self.ansible_vars_file)
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

    def _load_reference_architecture(self):
        try:
            with open(self.reference_architecture_path) as json_file:
                self.reference_architecture = json.loads(json_file.read())
        except json.decoder.JSONDecodeError as e:
            msg = ("Unable to load the reference architecture spec. file %s"
                   % self.reference_architecture_path)
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

    def _build_terraform_vars(self, env):
        # Load reference architecture specs.
        self._load_reference_architecture()

        ra = self.reference_architecture[env.reference_architecture]
        pg_spec = env.cloud_spec['postgres_server']
        os_spec = env.cloud_spec['available_os'][env.operating_system]

        self.terraform_vars = dict(
            cluster_name=self.name,
            replication_type=ra['replication_type'],
            ssh_user=os_spec['ssh_user'],
            ssh_priv_key=self.ssh_priv_key,
            ssh_pub_key=self.ssh_pub_key,
            image=os_spec['image'],
            barman=ra['barman'],
            pooler_local=ra['pooler_local'],
            pooler_type=ra['pooler_type']
        )

        # AWS case
        if env.cloud == 'aws':
            self.terraform_vars.update(dict(
                aws_region=env.aws_region,
                aws_ami_id=getattr(env, 'aws_ami_id', None) or None,
            ))

        # Postgres servers terraform_vars
        self.terraform_vars.update(dict(
            postgres_server=dict(
                count=ra['pg_count'],
                instance_type=pg_spec['instance_type'],
                volume=pg_spec['volume'],
                additional_volumes=pg_spec['additional_volumes']
            )
        ))

        # PEM server terraform_vars
        pem_server_spec = env.cloud_spec['pem_server']
        self.terraform_vars.update(dict(
            pem_server=dict(
                count=1 if ra['pem_server'] else 0,
                instance_type=pem_server_spec['instance_type'],
                volume=pem_server_spec['volume']
            )
        ))

        # Barman server terraform_vars
        barman_server_spec = env.cloud_spec['barman_server']
        self.terraform_vars.update(dict(
            barman_server=dict(
                count=1 if ra['barman_server'] else 0,
                instance_type=barman_server_spec['instance_type'],
                volume=barman_server_spec['volume'],
                additional_volumes=barman_server_spec['additional_volumes']
            )
        ))

        # Pooler servers terraform_vars
        pooler_server_spec = env.cloud_spec['pooler_server']
        self.terraform_vars.update(dict(
            pooler_server=dict(
                count=ra['pooler_count'],
                instance_type=pooler_server_spec['instance_type'],
                volume=pooler_server_spec['volume']
            )
        ))

    def _build_ansible_vars(self, env):
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)

        os_spec = env.cloud_spec['available_os'][env.operating_system]
        pg_spec = env.cloud_spec['postgres_server']

        self.ansible_vars = dict(
            reference_architecture=env.reference_architecture,
            cluster_name=self.name,
            pg_type=env.postgres_type,
            pg_version=env.postgres_version,
            yum_username=edb_repo_username,
            yum_password=edb_repo_password,
            ssh_user=os_spec['ssh_user'],
            ssh_priv_key=self.ssh_priv_key
        )
        # Add configuration for pg_data and pg_wal accordingly to the number
        # of additional volumes
        if pg_spec['additional_volumes']['count'] > 0:
            self.ansible_vars.update(dict(pg_data='/pgdata/pg_data'))
        if pg_spec['additional_volumes']['count'] > 1:
            self.ansible_vars.update(dict(pg_wal='/pgwal/pg_wal'))

    def show_logs(self, tail):
        if not os.path.exists(self.log_file):
            raise ProjectError("Log file %s not found" % self.log_file)

        if not tail:
            # Read the whole file and write its content to stdout
            with open(self.log_file, "r") as f:
                for l in f.readlines():
                    sys.stdout.write(l)
        else:
            with open(self.log_file, "r") as f:
                # Go to the end of the file
                f.seek(0, 2)
                while True:
                    l = f.readline()
                    if not l:
                        time.sleep(0.1)
                        continue
                    sys.stdout.write(l)

    def remove(self):
        if os.path.exists(self.log_file):
            with AM("Removing log file %s" % self.log_file):
                os.unlink(self.log_file)
        with AM("Removing project directory %s" % self.project_path):
            shutil.rmtree(self.project_path)

    def show_configuration(self):
        self._load_terraform_vars()
        self._load_ansible_vars()

        try:
            json_output = json.dumps(
                dict(
                    ansible=self.ansible_vars,
                    terraform=self.terraform_vars
                ),
                indent=2
            )
        except Exception as e:
            msg = "Unable to convert the configuration to JSON"
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

        sys.stdout.write(json_output)
        sys.stdout.flush()

    def provision(self):
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path
        )
        with AM("Terraform project initialization"):
            terraform.init()
        with AM("Applying cloud resources creation"):
            terraform.apply(self.terraform_vars_file)

        # Checking instance availability
        cloud_cli = CloudCli(self.cloud)
        self._load_terraform_vars()
        if self.cloud == 'aws':
            with AM(
                "Checking instances availability in region %s"
                % self.terraform_vars['aws_region']
            ):
                cloud_cli.cli.check_instances_availability(
                    self.terraform_vars['aws_region']
                )
        with AM("SSH configuration"):
            terraform.exec_add_host_sh()

    def destroy(self):
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path
        )
        with AM("Destroying cloud resources"):
            terraform.destroy(self.terraform_vars_file)

    def deploy(self, no_install_collection):
        inventory_data = None
        ansible = AnsibleCli(self.project_path)

        # Load ansible vars
        self._load_ansible_vars()

        if not no_install_collection:
            with AM(
                "Installing Ansible collection %s"
                % self.ansible_collection_name
            ):
                ansible.install_collection(self.ansible_collection_name)

        # Building extra vars to pass to ansible because it's not safe to pass
        # the content of ansible_vars as it.
        extra_vars=dict(
            pg_type=self.ansible_vars['pg_type'],
            pg_version=self.ansible_vars['pg_version'],
            yum_username=self.ansible_vars['yum_username'],
            yum_password=self.ansible_vars['yum_password'],
            pass_dir=os.path.join(self.project_path, '.edbpass')
        )
        if self.ansible_vars.get('pg_data'):
            extra_vars.update(dict(
                pg_data=self.ansible_vars['pg_data']
            ))
        if self.ansible_vars.get('pg_wal'):
            extra_vars.update(dict(
                pg_wal=self.ansible_vars['pg_wal']
            ))

        with AM("Deploying components with Ansible"):
            ansible.run_playbook(
                self.ansible_vars['ssh_user'],
                self.ansible_vars['ssh_priv_key'],
                self.ansible_inventory,
                self.ansible_playbook,
                json.dumps(extra_vars)
            )

        with AM("Extracting data the inventory file"):
            inventory_data = ansible.list_inventory(self.ansible_inventory)

        # Display inventory informations
        self.display_inventory(inventory_data)

    def display_inventory(self, inventory_data):
        servers = []

        if not self.ansible_vars:
            self._load_ansible_vars()
        ssh_user = self.ansible_vars['ssh_user']

        def _p(s):
            sys.stdout.write(s)

        sys.stdout.flush()
        _p("\n")

        if 'pemserver' in inventory_data['all']['children']:
            # Display PEM server informations
            pem_user = 'pemadmin'
            pem_name = inventory_data['pemserver']['hosts'][0]
            pem_hostvars = inventory_data['_meta']['hostvars'][pem_name]
            with open(
                os.path.join(
                    self.project_path, '.edbpass', '%s_pass' % pem_user
                )
            ) as f:
                pem_password = f.read()

            _p(
                "PEM Server: https://%s:8443/pem\n"
                % pem_hostvars['ansible_host']
            )
            _p("PEM User: %s\n" % pem_user)
            _p("PEM Password: %s\n" % pem_password)

        max_l_name = 0
        for k, v in inventory_data['_meta']['hostvars'].items():
            servers.append([
                k,
                v['ansible_host'],
                v['private_ip']
            ])
            if len(k) > max_l_name:
                max_l_name = len(k)

        max_l_name += 3
        max_l_ip = 18
        max_l_ssh_user = len(ssh_user) + 3 if len(ssh_user) > 7 else 10

        # Display headers
        headers = ['Name', 'Public IP', 'SSH User', 'Private IP']
        _p(headers[0].center(max_l_name))
        _p(headers[1].center(max_l_ip))
        _p(headers[2].center(max_l_ssh_user))
        _p(headers[3].center(max_l_ip))
        _p("\n")
        _p("=" * (max_l_name + + max_l_ssh_user + max_l_ip * 2))
        _p("\n")

        for line in sorted(servers, key=lambda x: x[0]):
            # Display each line
            _p(line[0].rjust(max_l_name))
            _p(line[1].rjust(max_l_ip))
            _p(ssh_user.rjust(max_l_ssh_user))
            _p(line[2].rjust(max_l_ip))
            _p("\n")

        _p("\n")
        sys.stdout.flush()
