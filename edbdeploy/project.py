import errno
import getpass
import json
import logging
import os
import re
import shutil
import sys
import stat
import time
import yaml

from .cloud import CloudCli, AWSCli, AWSRDSCli, AzureCli, GCloudCli
from .terraform import TerraformCli
from .ansible import AnsibleCli
from .action import ActionManager as AM
from .specifications import default_spec, merge_user_spec
from .spec.reference_architecture import ReferenceArchitectureSpec
from .password import (
    get_password,
    list_passwords,
    random_password,
    save_password,
)
from .errors import ProjectError

from .spec.aws_rds import TPROCC_GUC


class Project:

    projects_root_path = os.getenv(
        'EDB_DEPLOY_DIR',
        os.path.join(os.path.expanduser("~"), ".edb-deployment")
    )
    # Path that should contain 3rd party tools binaries when they are installed
    # by the prerequisites installation script.
    cloud_tools_bin_path = os.path.join(
        os.path.expanduser("~"),
        '.edb-cloud-tools',
        'bin'
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

    def check_versions(self):
        # Check Ansible version
        ansible = AnsibleCli('dummy', bin_path=self.cloud_tools_bin_path)
        ansible.check_version()

        # Check only Ansible version when working with baremetal deployment
        if self.cloud == 'baremetal':
            return

        # Check Terraform version
        terraform = TerraformCli('dummy', 'dummy',
                                 bin_path=self.cloud_tools_bin_path)
        terraform.check_version()
        # Check cloud vendor CLI/SDK version
        cloud_cli = CloudCli(self.cloud, bin_path=self.cloud_tools_bin_path)
        cloud_cli.check_version()

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

    @staticmethod
    def create_cloud_tools_bin_dir():
        try:
            os.makedirs(Project.cloud_tools_bin_path)
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
        if self.cloud == 'baremetal':
            # Create only project directory when working with baremetal
            # deployment.
            with AM("Creating project directory %s" % self.project_path):
                os.makedirs(self.project_path)
            return

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

    def _load_cloud_specs(self, env):
        """
        Load Cloud Vendor specifications based on the merge of default and user
        defined specs, passed with the help of the -s option.
        """
        cloud_spec = None
        with AM("Loading Cloud specifications"):
            if getattr(env, 'spec_file', False):
                user_spec = self._load_spec_file(env.spec_file.name)
                cloud_spec = merge_user_spec(
                    env.cloud,
                    user_spec,
                    getattr(env, 'reference_architecture', None)
                )
            else:
                cloud_spec = default_spec(
                    env.cloud, getattr(env, 'reference_architecture', None)
                )

        logging.debug("cloud_specs=%s", cloud_spec)
        return cloud_spec

    def _copy_ssh_keys(self, env):
        """
        Copy SSH keys pair into project directory.
        """
        with AM("Copying SSH key pair into %s" % self.project_path):
            # Ensure SSH keys have been defined
            if env.ssh_priv_key is None:
                raise ProjectError("SSH private key not defined")
            if env.ssh_pub_key is None:
                raise ProjectError("SSH public key not defined")

            shutil.copy(env.ssh_priv_key.name, self.ssh_priv_key)
            shutil.copy(env.ssh_pub_key.name, self.ssh_pub_key)
            os.chmod(self.ssh_priv_key, stat.S_IREAD | stat.S_IWRITE)
            os.chmod(self.ssh_pub_key, stat.S_IREAD | stat.S_IWRITE)

    def _transform_terraform_tpl(self):
        """
        Transform project's Terraform templates into .tf files by replacing the
        %PROJECT_NAME% placeholder by project name.
        """
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

    def _build_terraform_vars_file(self, env):
        """
        Build and save the file that contains Terraform variables.
        """
        with AM("Building Terraform vars file %s" % self.terraform_vars_file):
            self._build_terraform_vars(env)
            logging.debug("terraform_vars=%s", self.terraform_vars)
            # Save Terraform vars
            self._save_terraform_vars()

    def _build_ansible_vars_file(self, env):
        """
        Build and save the file that contains Ansible variables.
        """
        with AM("Building Ansible vars file %s" % self.ansible_vars_file):
            self._build_ansible_vars(env)
            logging.debug("ansible_vars=%s", self.ansible_vars)
            # Save Ansible vars
            self._save_ansible_vars()

    def _build_ansible_inventory(self, env):
        """
        Build Ansible inventory file for baremetal deployment.
        """
        inventory = {
            'all': {
                'children': {
                    'pemserver': {
                        'hosts': {
                            env.cloud_spec['pem_server_1']['name']: {
                                'ansible_host': env.cloud_spec['pem_server_1']['public_ip'],
                                'private_ip': env.cloud_spec['pem_server_1']['private_ip'],
                            }
                        }
                    },
                    'barmanserver': {
                        'hosts': {
                            env.cloud_spec['backup_server_1']['name']: {
                                'ansible_host': env.cloud_spec['backup_server_1']['public_ip'],
                                'private_ip': env.cloud_spec['backup_server_1']['private_ip'],
                            }
                        }
                    },
                    'primary': {
                        'hosts': {
                            env.cloud_spec['postgres_server_1']['name']: {
                                'ansible_host': env.cloud_spec['postgres_server_1']['public_ip'],
                                'private_ip': env.cloud_spec['postgres_server_1']['private_ip'],
                                'pem_agent': True,
                                'pem_server_private_ip': env.cloud_spec['pem_server_1']['private_ip'],
                                'barman': True,
                                'barman_server_private_ip': env.cloud_spec['backup_server_1']['private_ip'],
                                'barman_backup_method': 'postgres',
                            }
                        }
                    }
                }
            }
        }
        if env.reference_architecture in ['EDB-RA-2', 'EDB-RA-3']:
            inventory['all']['children'].update({
                'standby': {
                    'hosts': {}
                }
            })
            for i in range(2, 4):
                inventory['all']['children']['standby']['hosts'].update({
                    env.cloud_spec['postgres_server_%s' % i]['name']: {
                        'ansible_host': env.cloud_spec['postgres_server_%s' % i]['public_ip'],
                        'private_ip': env.cloud_spec['postgres_server_%s' % i]['private_ip'],
                        'pem_agent': True,
                        'pem_server_private_ip': env.cloud_spec['pem_server_1']['private_ip'],
                        'barman': True,
                        'barman_server_private_ip': env.cloud_spec['backup_server_1']['private_ip'],
                        'barman_backup_method': 'postgres',
                        'upstream_node_private_ip': env.cloud_spec['postgres_server_1']['private_ip'],
                        'replication_type': 'synchronous' if i == 2 else 'asynchronous',
                    }
                })
        if env.reference_architecture == 'EDB-RA-3':
            inventory['all']['children'].update({
                'pgpool2': {
                    'hosts': {}
                }
            })
            for i in range(1, 4):
                inventory['all']['children']['pgpool2']['hosts'].update({
                    env.cloud_spec['pooler_server_%s' % i]['name']: {
                        'ansible_host': env.cloud_spec['pooler_server_%s' % i]['public_ip'],
                        'private_ip': env.cloud_spec['pooler_server_%s' % i]['private_ip'],
                        'primary_node_private_ip': env.cloud_spec['postgres_server_1']['private_ip'],
                    }
                })

        with open(self.ansible_inventory, 'w') as f:
            f.write(yaml.dump(inventory, default_flow_style=False))

    def _copy_ansible_playbook(self):
        """
        Copy reference architecture Ansible playbook into project directory.
        """
        with AM("Copying Ansible playbook file %s" % self.ansible_playbook):
            shutil.copy(
                os.path.join(
                    self.ansible_share_path,
                    "%s.yml" % self.ansible_vars['reference_architecture']
                ),
                self.ansible_playbook
            )

    def _get_instance_types(self, node_types):
        """
        Get the list of instance type from Terraform vars, based on node type.
        """
        instance_types = []

        for node_type in node_types:
            node = self.terraform_vars.get(node_type)
            if not node:
                continue
            if node['instance_type'] not in instance_types:
                instance_types.append(node['instance_type'])

        return instance_types

    def _aws_check_instance_image(self, env):
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

    def _awsrds_check_instance_image(self, env):
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
            pattern = re.compile("^db\.")
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

    def _awsrdsaurora_check_instance_image(self, env):
        """
        Check AWS RDS Aurora DB class instance, EC2 instance type and EC2 image
        id availability in specified region.
        """
        # RDS and RDS Aurora checks are similar
        self._awsrds_check_instance_image(env)

    def _azure_check_instance_image(self, env):
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

    def _gcloud_check_instance_image(self, env):
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

    def configure(self, env):
        """
        configure sub-command
        """
        # Load specifications
        env.cloud_spec = self._load_cloud_specs(env)

        # Copy SSH keys
        self._copy_ssh_keys(env)

        # Transform Terraform templates
        if env.cloud != 'baremetal':
            self._transform_terraform_tpl()

        # RDS/Aurora: Build master user random password
        if env.cloud in ['aws-rds', 'aws-rds-aurora']:
            with AM("Building master user password"):
                save_password(self.project_path, 'postgres', random_password())

        # Build the vars files for Terraform and Ansible
        if env.cloud != 'baremetal':
            self._build_terraform_vars_file(env)
        self._build_ansible_vars_file(env)

        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()

        # Build inventory file for baremetal deployment
        if env.cloud == 'baremetal':
            with AM(
                "Build Ansible inventory file %s" % self.ansible_inventory
            ):
                self._build_ansible_inventory(env)

        # Check Cloud Instance type and Image availability. This is achieved by
        # executing the _<cloud-vendor>_check_instance_image method, if this
        # attribute exists.
        m = "_%s_check_instance_image" % env.cloud.replace('-', '')
        if getattr(self, m, None):
            getattr(self, m)(env)

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

    def _aws_build_terraform_vars(self, env):
        """
        Build Terraform variable for AWS provisioning
        """
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']
        hammerdb = env.cloud_spec['hammerdb_server']

        self.terraform_vars = {
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os['image'],
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
            'replication_type': ra['replication_type'],
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

    def _gcloud_build_terraform_vars(self, env):
        """
        Build Terraform variable for GCloud provisioning
        """
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        barman = env.cloud_spec['barman_server']
        pooler = env.cloud_spec['pooler_server']

        self.terraform_vars = {
            'barman': ra['barman'],
            'barman_server': {
                'count': 1 if ra['barman_server'] else 0,
                'instance_type': barman['instance_type'],
                'volume': barman['volume'],
                'additional_volumes': barman['additional_volumes'],
            },
            'cluster_name': self.name,
            'gcloud_image': os['image'],
            'gcloud_region': env.gcloud_region,
            'gcloud_credentials': env.gcloud_credentials.name,
            'gcloud_project_id': env.gcloud_project_id,
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
            'replication_type': ra['replication_type'],
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

    def _azure_build_terraform_vars(self, env):
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
            'replication_type': ra['replication_type'],
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

    def _awsrds_build_terraform_vars(self, env):
        """
        Build Terraform variable for AWS RDS provisioning
        """
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        hammerdb = env.cloud_spec['hammerdb_server']
        guc = TPROCC_GUC

        self.terraform_vars = {
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os['image'],
            'aws_region': env.aws_region,
            'cluster_name': self.name,
            'guc_effective_cache_size': guc[env.shirt]['effective_cache_size'],
            'guc_max_wal_size': guc[env.shirt]['max_wal_size'],
            'guc_shared_buffers': guc[env.shirt]['shared_buffers'],
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
            'pg_password': get_password(self.project_path, 'postgres'),
            'pg_version': env.postgres_version,
            'postgres_server': {
                'count': ra['pg_count'],
                'instance_type': pg['instance_type'],
                'volume': pg['volume'],
            },
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

    def _awsrdsaurora_build_terraform_vars(self, env):
        """
        Build Terraform variable for AWS RDS Aurora provisioning
        """
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        hammerdb = env.cloud_spec['hammerdb_server']

        self.terraform_vars = {
            'aws_ami_id': getattr(env, 'aws_ami_id', None),
            'aws_image': os['image'],
            'aws_region': env.aws_region,
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
            'pg_password': get_password(self.project_path, 'postgres'),
            'pg_version': env.postgres_version,
            'postgres_server': {
                'count': ra['pg_count'],
                'instance_type': pg['instance_type'],
            },
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

    def _build_terraform_vars(self, env):
        """
        Build Terraform variables based on the environment.
        """

        # Calling the Cloud Vendor dedicated method:
        # _<cloud-vendor>_build_terraform_vars()
        m = "_%s_build_terraform_vars" % env.cloud.replace('-', '')
        if getattr(self, m, None):
            getattr(self, m)(env)

    def _iaas_build_ansible_vars(self, env):
        """
        Build Ansible variables for the IaaS cloud vendors: aws, gcloud and
        azure.
        """
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)

        os_spec = env.cloud_spec['available_os'][env.operating_system]
        pg_spec = env.cloud_spec['postgres_server']

        self.ansible_vars = {
            'reference_architecture': env.reference_architecture,
            'cluster_name': self.name,
            'pg_type': env.postgres_type,
            'pg_version': env.postgres_version,
            'repo_username': edb_repo_username,
            'repo_password': edb_repo_password,
            'ssh_user': os_spec['ssh_user'],
            'ssh_priv_key': self.ssh_priv_key,
            'efm_version': env.efm_version,
        }

        # Add configuration for pg_data and pg_wal accordingly to the
        # number of additional volumes
        if pg_spec['additional_volumes']['count'] > 0:
            self.ansible_vars.update(dict(pg_data='/pgdata/pg_data'))
        if pg_spec['additional_volumes']['count'] > 1:
            self.ansible_vars.update(dict(pg_wal='/pgwal/pg_wal'))

    def _dbaas_build_ansible_vars(self, env):
        """
        Build Ansible variables for the DBaaS cloud vendors: aws-rds and
        aws-rds-aurora.
        """
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)

        os_spec = env.cloud_spec['available_os'][env.operating_system]

        self.ansible_vars = {
            'reference_architecture': env.reference_architecture,
            'cluster_name': self.name,
            'pg_type': env.postgres_type,
            'pg_version': env.postgres_version,
            'repo_username': edb_repo_username,
            'repo_password': edb_repo_password,
            'ssh_user': os_spec['ssh_user'],
            'ssh_priv_key': self.ssh_priv_key,
        }

    def _aws_build_ansible_vars(self, env):
        return self._iaas_build_ansible_vars(env)

    def _azure_build_ansible_vars(self, env):
        return self._iaas_build_ansible_vars(env)

    def _gcloud_build_ansible_vars(self, env):
        return self._iaas_build_ansible_vars(env)

    def _awsrds_build_ansible_vars(self, env):
        return self._dbaas_build_ansible_vars(env)

    def _awsrdsaurora_build_ansible_vars(self, env):
        return self._dbaas_build_ansible_vars(env)

    def _baremetal_build_ansible_vars(self, env):
        """
        Build Ansible variables for baremetal deployment.
        """
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)

        if env.cloud_spec['ssh_user'] is not None:
            ssh_user = env.cloud_spec['ssh_user']
        else:
            # Use current username for SSH connection if not set
            ssh_user = getpass.getuser()

        self.ansible_vars = {
            'reference_architecture': env.reference_architecture,
            'cluster_name': self.name,
            'pg_type': env.postgres_type,
            'pg_version': env.postgres_version,
            'repo_username': edb_repo_username,
            'repo_password': edb_repo_password,
            'ssh_user': ssh_user,
            'ssh_priv_key': self.ssh_priv_key,
            'efm_version': env.efm_version,
        }

        # Add configuration for pg_data and pg_wal
        if env.cloud_spec['pg_data'] is not None:
            self.ansible_vars.update(dict(pg_data=env.cloud_spec['pg_data']))
        if env.cloud_spec['pg_wal'] is not None:
            self.ansible_vars.update(dict(pg_wal=env.cloud_spec['pg_wal']))

    def _build_ansible_vars(self, env):
        """
        Build Ansible variables based on the environment.
        """
        # Calling the Cloud Vendor dedicated method:
        # _<cloud-vendor>_build_ansible_vars()
        m = "_%s_build_ansible_vars" % env.cloud.replace('-', '')
        if getattr(self, m, None):
            getattr(self, m)(env)

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
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
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
        self._load_ansible_vars()
        output = dict(ansible=self.ansible_vars)

        if self.cloud != 'baremetal':
            self._load_terraform_vars()
            output.update(terraform=self.terraform_vars)

        try:
            json_output = json.dumps(output, indent=2)
        except Exception as e:
            msg = "Unable to convert the configuration to JSON"
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

        sys.stdout.write(json_output)
        sys.stdout.flush()

    def provision(self):
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
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
        cloud_cli = CloudCli(self.cloud, bin_path=self.cloud_tools_bin_path)
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
        # AWS RDS case
        if self.cloud == 'aws-rds':
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
                     + self.terraform_vars['pooler_server']['count']
                     + self.terraform_vars['hammerdb_server']['count'])
                )


        with AM("SSH configuration"):
            terraform.exec_add_host_sh()

    def destroy(self):
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        self.update_state('terraform', 'DESTROYING')
        with AM("Destroying cloud resources"):
            terraform.destroy(self.terraform_vars_file)
        self.update_state('terraform', 'DESTROYED')
        self.update_state('ansible', 'UNKNOWN')

    def deploy(self, no_install_collection,
               pre_deploy_ansible=None,
               post_deploy_ansible=None,
               skip_main_playbook=False):

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path = self.cloud_tools_bin_path
        )

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
            repo_username=self.ansible_vars['repo_username'],
            repo_password=self.ansible_vars['repo_password'],
            pass_dir=os.path.join(self.project_path, '.edbpass')
        )
        if self.ansible_vars.get('efm_version'):
            extra_vars.update(dict(
                efm_version=self.ansible_vars['efm_version'],
            ))
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

    def display_passwords(self):
        try:
            states = self.load_states()
        except Exception as e:
            states={}
        status = states.get('ansible', 'UNKNOWN')
        if status in ['DEPLOYED', 'DEPLOYING']:
            if status == 'DEPLOYING':
                print("WARNING: project is in deploying state")

            Project.display_table(
                ['Username','Password'],
                list_passwords(self.project_path)
            )

    def display_details(self):
        try:
            states = self.load_states()
        except Exception as e:
            states={}
        status = states.get('ansible', 'UNKNOWN')
        if status in ['DEPLOYED', 'DEPLOYING']:
            if status == 'DEPLOYING':
                print("WARNING: project is in deploying state")
            inventory_data = None
            ansible = AnsibleCli(
                self.project_path,
                bin_path = self.cloud_tools_bin_path
            )
            with AM("Extracting data from the inventory file"):
                inventory_data = ansible.list_inventory(self.ansible_inventory)
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
            pem_password = get_password(self.project_path, pem_user)

            _p(
                "PEM Server: https://%s:8443/pem\n"
                % pem_hostvars['ansible_host']
            )
            _p("PEM User: %s\n" % pem_user)
            _p("PEM Password: %s\n" % pem_password)

        # Build the nodes table
        rows = []
        for name, vars in inventory_data['_meta']['hostvars'].items():

            # Handle special case of managed DB instances: no SSH and no
            # private IP
            managed = False
            if vars['ansible_host'].endswith('.rds.amazonaws.com'):
                managed = True

            rows.append([
                name,
                vars['ansible_host'],
                self.ansible_vars['ssh_user'] if not managed else '',
                vars['private_ip'] if not managed else '',
            ])

        Project.display_table(
            ['Name', 'Public IP', 'SSH User', 'Private IP'],
            rows
        )

    @staticmethod
    def list(cloud):
        projects_path = os.path.join(Project.projects_root_path, cloud)
        headers = ["Name", "Path", "Machines", "Resources", "Components"]
        rows = []
        try:
            # Case when projects' path does not yet exist
            if not os.path.exists(projects_path):
                Project.display_table(headers, [])
                return

            for project_name in os.listdir(projects_path):
                project_path = os.path.join(projects_path, project_name)
                if not os.path.isdir(project_path):
                    continue

                project = Project(cloud, project_name)

                terraform_resource_count = 0
                terraform = TerraformCli(
                    project.project_path,
                    project.terraform_plugin_cache_path,
                    bin_path=Project.cloud_tools_bin_path
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

            Project.display_table(headers, rows)

        except OSError as e:
            msg = "Unable to list projects in %s" % projects_path
            logging.error(msg)
            logging.exception(str(e))
            raise ProjectError(msg)

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
    def show_specs(cloud, reference_architecture=None):
        sys.stdout.write(
            json.dumps(default_spec(cloud, reference_architecture), indent=2)
        )
        sys.stdout.flush()

    @staticmethod
    def setup_tools(cloud):
        """
        Prerequisites installation
        """
        # List of the tools and their supported cloud vendors
        tools = [
            {
                'name': 'Ansible',
                'cli': AnsibleCli(
                    'dummy', bin_path=Project.cloud_tools_bin_path
                ),
                'cloud_vendors': [
                    'aws', 'aws-rds', 'aws-rds-aurora', 'azure', 'gcloud',
                    'baremetal'
                ]
            },
            {
                'name': 'Terraform',
                'cli': TerraformCli(
                    'dummy', 'dummy', bin_path=Project.cloud_tools_bin_path
                ),
                'cloud_vendors': [
                    'aws', 'aws-rds', 'aws-rds-aurora', 'azure', 'gcloud'
                ]
            },
            {
                'name': 'AWS Cli',
                'cli': AWSCli(bin_path=Project.cloud_tools_bin_path),
                'cloud_vendors': ['aws', 'aws-rds', 'aws-rds-aurora']
            },
            {
                'name': 'Azure Cli',
                'cli': AzureCli(bin_path=Project.cloud_tools_bin_path),
                'cloud_vendors': ['azure']
            },
            {
                'name': 'GCloud Cli',
                'cli': GCloudCli(bin_path=Project.cloud_tools_bin_path),
                'cloud_vendors': ['gcloud']
            },
        ]

        for tool in tools:
            # Install the tool only for appropriated cloud vendors
            if cloud not in tool['cloud_vendors']:
                continue

            try:
                # Check if the tool is already installed and in supported
                # version
                tool['cli'].check_version()
                print("INFO: %s is already installed in supported version"
                      % tool['name'])
            except Exception as e:
                # Proceed with the installation
                with AM("%s installation" % tool['name']):
                    tool['cli'].install(
                        os.path.dirname(Project.cloud_tools_bin_path)
                    )
