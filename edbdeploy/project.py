import errno
import json
import logging
import os
import re
import shutil
import sys
import stat
import time

from .cloud import CloudCli, AWSCli, AzureCli, GCloudCli
from .terraform import TerraformCli
from .ansible import AnsibleCli
from .action import ActionManager as AM
from .specifications import default_spec, merge_user_spec
from .spec.reference_architecture import ReferenceArchitectureSpec


class ProjectError(Exception):
    pass


class Project:

    projects_root_path = os.getenv(
        'EDB_DEPLOY_DIR',
        os.path.join(os.path.expanduser("~"), ".edb-deployment")
    )
    terraform_share_path = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        'data',
        'terraform'
    )
    ansible_share_path = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        'data',
        'ansible'
    )
    terraform_templates = ['variables.tf.template', 'tags.tf.template']
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
        self.terraform_plugin_cache_path = os.path.join(
            self.projects_root_path,
            '.terraform_plugin_cache'
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
        self.reference_architecture = ReferenceArchitectureSpec
        self.log_file = os.path.join(
            self.projects_root_path, "log", self.cloud, "%s.log" % self.name
        )
        self.ansible_playbook = os.path.join(self.project_path, 'playbook.yml')
        self.ansible_inventory = os.path.join(
            self.project_path,
            'inventory.yml'
        )
        self.state_file = os.path.join(self.project_path, 'state.json')

    def create_log_dir(self):
        try:
            os.makedirs(os.path.dirname(self.log_file))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise ProjectError(str(e))
        except Exception as e:
            raise ProjectError(str(e))

    @staticmethod
    def create_root_log_dir():
        try:
            os.makedirs(os.path.join(Project.projects_root_path, "log"))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise ProjectError(str(e))
        except Exception as e:
            raise ProjectError(str(e))

    def exists(self):
        return os.path.exists(self.project_path)

    def init_state(self):
        with open(self.state_file, 'w') as f:
            f.write(json.dumps(dict()))

    def update_state(self, component, state):
        try:
            if not os.path.exists(self.state_file):
                self.init_state()

            with open(self.state_file, 'r') as f:
                states = json.loads(f.read())
            # Update component's state
            states[component] = state
            # Save the state file
            with open(self.state_file, 'w') as f:
                f.write(json.dumps(states))
        except Exception as e:
            msg = "Unable to update the state file %s" % self.state_file
            logging.error(msg)
            logging.exception(str(e))
            raise ProjectError(msg)

    def load_states(self):
        try:
            with open(self.state_file, 'r') as f:
                return json.loads(f.read())
        except Exception as e:
            msg = "Unable to read the state file %s" % self.state_file
            logging.error(msg)
            logging.exception(str(e))
            raise ProjectError(msg)

    def create(self):
        # Copy terraform code
        with AM("Copying Terraform code from into %s" % self.project_path):
            try:
                shutil.copytree(self.terraform_path, self.project_path)
            except Exception as e:
                raise ProjectError(str(e))

        with AM("Initialzing state file"):
            self.init_state()

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
        # Load specifications
        with AM("Loading Cloud specifications"):
            if getattr(env, 'spec_file', False):
                user_spec = self._load_spec_file(env.spec_file.name)
                env.cloud_spec = merge_user_spec(env.cloud, user_spec)
            else:
                env.cloud_spec = default_spec(env.cloud)

            logging.debug("env.cloud_specs=%s", env.cloud_spec)

        # Copy SSH keys
        with AM("Copying SSH key pair into %s" % self.project_path):
            shutil.copy(env.ssh_priv_key.name, self.ssh_priv_key)
            shutil.copy(env.ssh_pub_key.name, self.ssh_pub_key)
            os.chmod(self.ssh_priv_key, stat.S_IREAD | stat.S_IWRITE)
            os.chmod(self.ssh_pub_key, stat.S_IREAD | stat.S_IWRITE)

        # Transform templates
        for template in self.terraform_templates:
            template_path = os.path.join(self.project_path, template)
            if not os.path.exists(template_path):
                continue
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

        # Build a list of instance_type accordingly to the specs
        instance_types = []
        node_types = ['postgres_server', 'pem_server', 'barman_server',
                      'pooler_server']
        for node_type in node_types:
            node = self.terraform_vars.get(node_type)
            if not node:
                continue
            if node['instance_type'] not in instance_types:
                instance_types.append(node['instance_type'])

        # AWS - Check instance type and image availability
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

        # Azure - Check instance type and image availability
        if env.cloud == 'azure':
            for instance_type in instance_types:
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

        # GCloud - Check instance type and image availability
        if env.cloud == 'gcloud':
            for instance_type in instance_types:
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

    def _build_terraform_vars(self, env):
        ra = self.reference_architecture[env.reference_architecture]
        pg_spec = env.cloud_spec['postgres_server']
        os_spec = env.cloud_spec['available_os'][env.operating_system]

        self.terraform_vars = dict(
            cluster_name=self.name,
            replication_type=ra['replication_type'],
            ssh_user=os_spec['ssh_user'],
            ssh_priv_key=self.ssh_priv_key,
            ssh_pub_key=self.ssh_pub_key,
            barman=ra['barman'],
            pooler_local=ra['pooler_local'],
            pooler_type=ra['pooler_type']
        )

        # AWS case
        if env.cloud == 'aws':
            self.terraform_vars.update(dict(
                aws_image=os_spec['image'],
                aws_region=env.aws_region,
                aws_ami_id=getattr(env, 'aws_ami_id', None) or None,
            ))
        # Azure case
        if env.cloud == 'azure':
            self.terraform_vars.update(dict(
                azure_region=env.azure_region,
                azure_publisher=os_spec['publisher'],
                azure_offer=os_spec['offer'],
                azure_sku=os_spec['sku']
            ))
        # GCloud case
        if env.cloud == 'gcloud':
            self.terraform_vars.update(dict(
                gcloud_image=os_spec['image'],
                gcloud_region=env.gcloud_region,
                gcloud_credentials=env.gcloud_credentials.name,
                gcloud_project_id=env.gcloud_project_id
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
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path
        )
        # Prevent project deletion if some cloud resources are still present
        # for this project.
        if terraform.count_resources() > 0:
            raise ProjectError(
                "Some cloud resources seem to be still present for this "
                "project, please destroy them with the 'destroy' sub-command"
            )

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

        self.update_state('terraform', 'INITIALIZATING')
        with AM("Terraform project initialization"):
            terraform.init()
        self.update_state('terraform', 'INITIALIZATED')

        self.update_state('terraform', 'PROVISIONING')
        with AM("Applying cloud resources creation"):
            terraform.apply(self.terraform_vars_file)
        self.update_state('terraform', 'PROVISIONED')

        # Checking instance availability
        cloud_cli = CloudCli(self.cloud)
        self._load_terraform_vars()

        # AWS case
        if self.cloud == 'aws':
            with AM(
                "Checking instances availability in region %s"
                % self.terraform_vars['aws_region']
            ):
                cloud_cli.cli.check_instances_availability(
                    self.terraform_vars['aws_region']
                )
        # Azure case
        if self.cloud == 'azure':
            with AM("Checking instances availability"):
                cloud_cli.cli.check_instances_availability(self.name)
        # GCloud case
        if self.cloud == 'gcloud':
            with AM(
                "Checking instances availability in region %s"
                % self.terraform_vars['gcloud_region']
            ):
                cloud_cli.cli.check_instances_availability(
                    self.name,
                    self.terraform_vars['gcloud_region'],
                    # Total number of nodes
                    (self.terraform_vars['postgres_server']['count']
                     + self.terraform_vars['barman_server']['count']
                     + self.terraform_vars['pem_server']['count']
                     + self.terraform_vars['pooler_server']['count'])
                )


        with AM("SSH configuration"):
            terraform.exec_add_host_sh()

    def destroy(self):
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path
        )

        self.update_state('terraform', 'DESTROYING')
        with AM("Destroying cloud resources"):
            terraform.destroy(self.terraform_vars_file)
        self.update_state('terraform', 'DESTROYED')
        self.update_state('ansible', 'UNKNOWN')

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

        self.update_state('ansible', 'DEPLOYING')
        with AM("Deploying components with Ansible"):
            ansible.run_playbook(
                self.ansible_vars['ssh_user'],
                self.ansible_vars['ssh_priv_key'],
                self.ansible_inventory,
                self.ansible_playbook,
                json.dumps(extra_vars)
            )
        self.update_state('ansible', 'DEPLOYED')

        with AM("Extracting data from the inventory file"):
            inventory_data = ansible.list_inventory(self.ansible_inventory)

        # Display inventory informations
        self.display_inventory(inventory_data)

    def display_inventory(self, inventory_data):
        if not self.ansible_vars:
            self._load_ansible_vars()

        def _p(s):
            sys.stdout.write(s)

        sys.stdout.flush()
        _p("\n")
        # Display PEM server informations
        if 'pemserver' in inventory_data['all']['children']:
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

        # Build the nodes table
        rows = []
        for name, vars in inventory_data['_meta']['hostvars'].items():
            rows.append([
                name,
                vars['ansible_host'],
                self.ansible_vars['ssh_user'],
                vars['private_ip']
            ])

        Project.display_table(
            ['Name', 'Public IP', 'SSH User', 'Private IP'],
            rows
        )

    @staticmethod
    def list(cloud):
        projects_path = os.path.join(Project.projects_root_path, cloud)
        rows = []
        try:
            for project_name in os.listdir(projects_path):
                project_path = os.path.join(projects_path, project_name)
                if not os.path.isdir(project_path):
                    continue

                project = Project(cloud, project_name)

                terraform_resource_count = 0
                terraform = TerraformCli(
                    project.project_path,
                    project.terraform_plugin_cache_path
                )
                terraform_resource_count = terraform.count_resources()

                try:
                    states = project.load_states()
                except Exception as e:
                    states={}

                rows.append([
                    project.name,
                    project.project_path,
                    states.get('terraform', 'UNKNOWN'),
                    str(terraform_resource_count),
                    states.get('ansible', 'UNKNOWN')
                ])

            Project.display_table(
                ["Name", "Path", "Machines", "Resources", "Components"],
                rows
            )

        except OSError as e:
            msg = "Unable to list projects in %s" % projects_path
            logging.error(msg)
            logging.exception(str(e))
            raise ProjectErro(msg)

    @staticmethod
    def display_table(headers, rows):
        def _p(s):
            sys.stdout.write(s)

        # Calculate max lengths
        max_lengths = [0 for i in range(len(headers))]
        for i in range(len(headers)):
            if len(headers[i]) > max_lengths[i]:
                max_lengths[i] = len(headers[i])
        for row in rows:
            for i in range(len(headers)):
                if len(row[i]) > max_lengths[i]:
                    max_lengths[i] = len(row[i])

        _p("\n")
        # Display headers
        for i in range(len(headers)):
            _p(headers[i].center(max_lengths[i] + 4))

        _p("\n")
        _p("=" * (sum(max_lengths) + 4 * len(max_lengths)))
        _p("\n")
        # Display rows
        for row in rows:
            for i in range(len(headers)):
                _p(row[i].rjust(max_lengths[i] + 4))
            _p("\n")
        _p("\n")
        sys.stdout.flush()

    @staticmethod
    def show_specs(cloud):
        sys.stdout.write(json.dumps(default_spec(cloud), indent=2))
        sys.stdout.flush()
