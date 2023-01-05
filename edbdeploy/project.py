import errno
import json
import logging
import os
import re
import shutil
import stat
from subprocess import CalledProcessError
import sys
import time
import yaml

from .action import ActionManager as AM
from .ansible import AnsibleCli
from .cloud import CloudCli, AWSCli, AzureCli, GCloudCli
from .errors import ProjectError
from .password import get_password, list_passwords
from .specifications import default_spec, merge_user_spec
from .spec.reference_architecture import ReferenceArchitectureSpec
from .system import exec_shell
from .terraform import TerraformCli
from .tpaexec import TPAexecCli
from . import __edb_ansible_version__


def exec_hook(obj, name, *args, **kwargs):
    # Inject specific method call.
    if getattr(obj, name, False):
        return getattr(obj, name)(*args, **kwargs)


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
    tpaexec_share_path = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        'data',
        'tpaexec'
    )
    vmware_share_path = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        'data',
        'vmware-wkstn'
    )
    virtualbox_share_path = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        'data',
        'virtualbox'
    )
    terraform_templates = ['variables.tf.template', 'tags.tf.template']
    ansible_collection_name = 'edb_devops.edb_postgres:>=%s,<4.0.0' % __edb_ansible_version__  # noqa

    def __init__(self, cloud, name, env, bin_path=None):
        self.env = env
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
        self.edb_creds_file = os.path.join(
            self.project_path,
            'edb-credentials'
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
        # Path to look up for executable
        self.bin_path = None
        # Force Ansible binary path if bin_path exists and contains
        # ansible file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'python')):
                self.bin_path = bin_path

        self.environ = os.environ

    def check_versions(self):
        # Check Ansible version
        ansible = AnsibleCli('dummy', bin_path=self.cloud_tools_bin_path)
        ansible.check_version()
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
        # Pre-create hook
        exec_hook(self, 'hook_pre_create')

        # Copy terraform code
        with AM("Copying Terraform code from into %s" % self.project_path):
            try:
                shutil.copytree(self.terraform_path, self.project_path)
            except Exception as e:
                raise ProjectError(str(e))
        with AM("Initializing state file"):
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
            shutil.copy(env.ssh_priv_key.name, self.ssh_priv_key)
            os.chmod(self.ssh_priv_key, stat.S_IREAD | stat.S_IWRITE)

            if not hasattr(env, 'ssh_pub_key'):
                # Baremetal does not require public key usage
                return

            if env.ssh_pub_key is None:
                raise ProjectError("SSH public key not defined")

            shutil.copy(env.ssh_pub_key.name, self.ssh_pub_key)
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
                        for line in f.readlines():
                            d.write(line.replace("%PROJECT_NAME%", self.name))
                os.unlink(template_path)

    def _init_terraform_vars(self, env):
        ra = self.reference_architecture[env.reference_architecture]
        pg = env.cloud_spec['postgres_server']
        os = env.cloud_spec['available_os'][env.operating_system]
        pem = env.cloud_spec['pem_server']
        dbt2_client = env.cloud_spec['dbt2_client']
        dbt2_driver = env.cloud_spec['dbt2_driver']
        hammerdb = env.cloud_spec['hammerdb_server']

        self.terraform_vars = {
            'barman': ra['barman'],
            'cluster_name': self.name,
            'dbt2': env.cloud_spec['dbt2'] if 'dbt2' in env.cloud_spec else ra['dbt2'],
            'dbt2_client': {
                'count': dbt2_client['count'] if 'count' in dbt2_client else ra['dbt2_client_count'],
                'instance_type': dbt2_client['instance_type'],
                'volume': dbt2_client['volume'],
            },
            'dbt2_driver': {
                'count': dbt2_driver['count'] if 'count' in dbt2_driver else ra['dbt2_client_count'],
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
            'pooler_type': ra['pooler_type'],
            'postgres_server': {
                'count': ra['pg_count'],
            },
            'pg_type': env.postgres_type,
            'replication_type': ra['replication_type'],
            'ssh_pub_key': self.ssh_pub_key,
            'ssh_priv_key': self.ssh_priv_key,
            'ssh_user': os['ssh_user'],
        }

        if 'barman_server' in env.cloud_spec:
            barman = env.cloud_spec['barman_server']
            self.terraform_vars.update({
                'barman_server': {
                    'count': ra['barman_server_count'],
                    'instance_type': barman['instance_type'],
                    'volume': barman['volume'],
                    'additional_volumes':
                            barman['additional_volumes'],
                },
            })

        if 'bdr_server' in env.cloud_spec:
            bdr = env.cloud_spec['bdr_server']
            self.terraform_vars.update({
                'bdr_server': {
                    'count': ra['bdr_server_count'],
                    'instance_type': bdr['instance_type'],
                    'volume': bdr['volume'],
                    'additional_volumes': bdr['additional_volumes'],
                },
            })

        if 'bdr_witness_server' in env.cloud_spec:
            bdr_witness = env.cloud_spec['bdr_witness_server']
            self.terraform_vars.update({
                'bdr_witness_server': {
                    'count': ra['bdr_witness_count'],
                    'instance_type': bdr_witness['instance_type'],
                    'volume': bdr_witness['volume'],
                },
            })

        if 'pooler_server' in env.cloud_spec:
            pooler = env.cloud_spec['pooler_server']
            self.terraform_vars.update({
                'pooler_server': {
                    'count': ra['pooler_count'],
                    'instance_type': pooler['instance_type'],
                    'volume': pooler['volume'],
                },
            })

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

    def _save_edb_credentials(self, env):
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)
        try:
            with open(self.edb_creds_file, "w") as text_file:
                text_file.write(edb_repo_username + ":" + edb_repo_password)
        except Exception as e:
            msg = ("Unable to save the EDB credentials file %s"
                   % self.edb_creds_file)
            logging.error(msg)
            logging.error(str(e))
            raise ProjectError(msg)

    def _build_ansible_inventory(self, env):
        """
        Build Ansible inventory file for baremetal and vmware and virtualbox deployments.
        """
        pem1 = env.cloud_spec['pem_server_1']
        backup1 = env.cloud_spec['backup_server_1']
        pg1 = env.cloud_spec['postgres_server_1']
        inventory = {
            'all': {
                'children': {
                    'pemserver': {
                        'hosts': {
                            pem1['name']: {
                                'ansible_host': pem1['public_ip'],
                                'private_ip': pem1['private_ip'],
                            }
                        }
                    },
                    'barmanserver': {
                        'hosts': {
                            backup1['name']: {
                                'ansible_host': backup1['public_ip'],
                                'private_ip': backup1['private_ip'],
                            }
                        }
                    },
                    'primary': {
                        'hosts': {
                            pg1['name']: {
                                'ansible_host': pg1['public_ip'],
                                'private_ip': pg1['private_ip'],
                                'pem_agent': True,
                                'pem_server_private_ip': pem1['private_ip'],
                                'barman': True,
                                'barman_server_private_ip': backup1['private_ip'],  # noqa
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
                pgi = env.cloud_spec['postgres_server_%s' % i]
                inventory['all']['children']['standby']['hosts'].update({
                    pgi['name']: {
                        'ansible_host': pgi['public_ip'],
                        'private_ip': pgi['private_ip'],
                        'pem_agent': True,
                        'pem_server_private_ip': pem1['private_ip'],
                        'barman': True,
                        'barman_server_private_ip': backup1['private_ip'],
                        'barman_backup_method': 'postgres',
                        'upstream_node_private_ip': pg1['private_ip'],
                        'replication_type': 'synchronous' if i == 2 else 'asynchronous',  # noqa
                    }
                })
        if env.reference_architecture == 'EDB-RA-3':
            inventory['all']['children'].update({
                'pgpool2': {
                    'hosts': {}
                }
            })
            for i in range(1, 4):
                pooleri = env.cloud_spec['pooler_server_%s' % i]
                inventory['all']['children']['pgpool2']['hosts'].update({
                    pooleri['name']: {
                        'ansible_host': pooleri['public_ip'],
                        'private_ip': pooleri['private_ip'],
                        'primary_node_private_ip': pg1['private_ip'],
                    }
                })

        # Don't do anything with dbt2 if the dbt2 key is not present
        if 'dbt2' in env.cloud_spec:
            inventory['all']['children']['primary']['hosts'][pg1['name']]['dbt2'] = True
            if env.cloud_spec['dbt2_client']['count'] > 0:
                inventory['all']['children'].update({
                    'dbt2_client': {
                        'hosts': {}
                    }
                })
                for i in range(env.cloud_spec['dbt2_client']['count']):
                    name = 'dbt2_client_' + str(i)
                    clienti = env.cloud_spec[name]
                    inventory['all']['children']['dbt2_client']['hosts'].update({
                        name: {
                            'ansible_host': clienti['public_ip'],
                            'private_ip': clienti['private_ip'],
                        }
                    })
            if env.cloud_spec['dbt2_driver']['count'] > 0:
                inventory['all']['children'].update({
                    'dbt2_driver': {
                        'hosts': {}
                    }
                })
                for i in range(env.cloud_spec['dbt2_driver']['count']):
                    name = 'dbt2_driver_' + str(i)
                    driveri = env.cloud_spec[name]
                    inventory['all']['children']['dbt2_driver']['hosts'].update({
                        name: {
                            'ansible_host': driveri['public_ip'],
                            'private_ip': driveri['private_ip'],
                        }
                    })

        with open(self.ansible_inventory, 'w') as f:
            f.write(yaml.dump(inventory, default_flow_style=False))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def _copy_ansible_playbook(self):
        """
        Copy reference architecture Ansible playbook into project directory.
        """
        with AM(
            "Copying Ansible playbook file into %s" % self.ansible_playbook
        ):
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

            if not (node['count'] > 0):
                # Do not check instance type availability if the number of
                # machine is zero.
                continue

            if node['instance_type'] not in instance_types:
                instance_types.append(node['instance_type'])

        return instance_types

    def configure(self, env):
        """
        configure sub-command
        """
        # Load specifications
        env.cloud_spec = self._load_cloud_specs(env)
        # Copy SSH keys
        self._copy_ssh_keys(env)

        # Post-configure hook
        exec_hook(self, 'hook_post_configure', env)

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
            'use_hostname': env.use_hostname,
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
            'pg_type': "DBaaS",
            'pg_version': env.postgres_version,
            'repo_username': edb_repo_username,
            'repo_password': edb_repo_password,
            'ssh_user': os_spec['ssh_user'],
            'ssh_priv_key': self.ssh_priv_key,
        }

    def show_logs(self, tail):
        if not os.path.exists(self.log_file):
            raise ProjectError("Log file %s not found" % self.log_file)

        if not tail:
            # Read the whole file and write its content to stdout
            with open(self.log_file, "r") as f:
                for line in f.readlines():
                    sys.stdout.write(line)
        else:
            with open(self.log_file, "r") as f:
                # Go to the end of the file
                f.seek(0, 2)
                while True:
                    line = f.readline()
                    if not line:
                        time.sleep(0.1)
                        continue
                    sys.stdout.write(line)

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

    def provision(self, env):
        # Load variables
        self._load_ansible_vars()
        self._load_terraform_vars()

        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        with AM("Terraform project initialization"):
            self.update_state('terraform', 'INITIALIZATING')
            terraform.init()
            self.update_state('terraform', 'INITIALIZATED')

        with AM("Applying cloud resources creation"):
            self.update_state('terraform', 'PROVISIONING')
            terraform.apply(self.terraform_vars_file)
            self.update_state('terraform', 'PROVISIONED')

        # inventory.yml and config.yml generation
        # Variables passed to template rendering functions
        render_vars = dict(
            reference_architecture=self.ansible_vars['reference_architecture'],
            cluster_name=self.ansible_vars['cluster_name'],
            pg_type=self.ansible_vars['pg_type'],
            pooler_local=self.terraform_vars['pooler_local'],
            pooler_type=self.terraform_vars['pooler_type'],
            replication_type=self.terraform_vars['replication_type'],
            ssh_priv_key=self.terraform_vars['ssh_priv_key'],
            ssh_user=self.terraform_vars['ssh_user'],
            dbt2=self.terraform_vars.get('dbt2', False),
        )
        # Ansible inventory.yml generation hook
        exec_hook(self, 'hook_inventory_yml', render_vars)

        # Checking instance availability
        cloud_cli = CloudCli(self.cloud, bin_path=self.cloud_tools_bin_path)
        # Instances availability checking hook
        exec_hook(self, 'hook_instances_avaiblability', cloud_cli)

        with AM("SSH configuration"):
            terraform.exec_add_host_sh()

    def destroy(self):
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        with AM("Destroying cloud resources"):
            self.update_state('terraform', 'DESTROYING')
            terraform.destroy(self.terraform_vars_file)
            self.update_state('terraform', 'DESTROYED')
            self.update_state('ansible', 'UNKNOWN')

    def deploy(self, no_install_collection,
               pre_deploy_ansible=None,
               post_deploy_ansible=None,
               skip_main_playbook=False,
               disable_pipelining=False):

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
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
        extra_vars = dict(
            pg_type=self.ansible_vars['pg_type'],
            pg_version=self.ansible_vars['pg_version'],
            repo_username=self.ansible_vars['repo_username'],
            repo_password=self.ansible_vars['repo_password'],
            pass_dir=os.path.join(self.project_path, '.edbpass'),
        )
        if self.ansible_vars.get('efm_version'):
            extra_vars.update(dict(
                efm_version=self.ansible_vars['efm_version'],
            ))
        if self.ansible_vars.get('ssh_pass'):
            extra_vars.update(dict(
                ansible_ssh_pass=self.ansible_vars['ssh_pass'],
            ))
        if self.ansible_vars.get('use_hostname'):
            extra_vars.update(dict(
                use_hostname=self.ansible_vars['use_hostname'],
            ))
        if self.ansible_vars.get('pg_data'):
            extra_vars.update(dict(
                pg_data=self.ansible_vars['pg_data']
            ))
        if self.ansible_vars.get('pg_wal'):
            extra_vars.update(dict(
                pg_wal=self.ansible_vars['pg_wal']
            ))

        # A separate YAML file is created with the for the DBaaS options with
        # database credentials that need to be passed to the Ansible playbooks.
        postgres_file = os.path.join(self.project_path, 'postgresql.yml')
        if os.path.isfile(postgres_file):
            with open(postgres_file, 'r') as file:
                yaml_in = yaml.safe_load(file)
                extra_vars.update(yaml_in)

        # Until this is resolved:
        # https://github.com/TPC-Council/HammerDB/issues/163
        if self.cloud == 'azure-db':
            extra_vars.update(dict(azure_db_hackery=True))

        if pre_deploy_ansible:
            with AM("Executing pre deploy playbook using Ansible"):
                ansible.run_playbook(
                    self.cloud,
                    self.ansible_vars['ssh_user'],
                    self.ansible_vars['ssh_priv_key'],
                    self.ansible_inventory,
                    pre_deploy_ansible.name,
                    json.dumps(extra_vars),
                    disable_pipelining=disable_pipelining,
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
                    json.dumps(extra_vars),
                    disable_pipelining=disable_pipelining,
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
                    json.dumps(extra_vars),
                    disable_pipelining=disable_pipelining,
                )

        if not skip_main_playbook:
            # Display inventory informations
            self.display_inventory(inventory_data)

    def display_passwords(self):
        try:
            states = self.load_states()
        except Exception:
            states = {}
        status = states.get('ansible', 'UNKNOWN')
        if status in ['DEPLOYED', 'DEPLOYING']:
            if status == 'DEPLOYING':
                print("WARNING: project is in deploying state")

            Project.display_table(
                ['Username', 'Password'],
                list_passwords(self.project_path)
            )

    def display_details(self):
        try:
            states = self.load_states()
        except Exception:
            states = {}
        status = states.get('ansible', 'UNKNOWN')
        if status in ['DEPLOYED', 'DEPLOYING']:
            if status == 'DEPLOYING':
                print("WARNING: project is in deploying state")
            inventory_data = None
            ansible = AnsibleCli(
                self.project_path,
                bin_path=self.cloud_tools_bin_path
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
        headers = ["Name", "Path", "Machines", "Resources", "Ansible State"]
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

                project = Project(cloud, project_name, {})

                terraform_resource_count = 0
                terraform = TerraformCli(
                    project.project_path,
                    project.terraform_plugin_cache_path,
                    bin_path=Project.cloud_tools_bin_path
                )
                terraform_resource_count = terraform.count_resources()

                try:
                    states = project.load_states()
                except Exception:
                    states = {}

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
                    'gcloud-sql', 'baremetal', 'aws-pot', 'azure-pot',
                    'gcloud-pot'
                ]
            },
            {
                'name': 'Terraform',
                'cli': TerraformCli(
                    'dummy', 'dummy', bin_path=Project.cloud_tools_bin_path
                ),
                'cloud_vendors': [
                    'aws', 'aws-rds', 'aws-rds-aurora', 'azure', 'gcloud',
                    'gcloud-sql', 'aws-pot', 'azure-pot', 'gcloud-pot'
                ]
            },
            {
                'name': 'AWS Cli',
                'cli': AWSCli(bin_path=Project.cloud_tools_bin_path),
                'cloud_vendors': [
                    'aws', 'aws-rds', 'aws-rds-aurora', 'aws-pot'
                ]
            },
            {
                'name': 'Azure Cli',
                'cli': AzureCli(bin_path=Project.cloud_tools_bin_path),
                'cloud_vendors': ['azure', 'azure-pot']
            },
            {
                'name': 'GCloud Cli',
                'cli': GCloudCli(bin_path=Project.cloud_tools_bin_path),
                'cloud_vendors': ['gcloud', 'gcloud-pot']
            },
            {
                'name': 'GCloud Cli',
                'cli': GCloudCli(bin_path=Project.cloud_tools_bin_path),
                'cloud_vendors': ['gcloud-sql']
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
            except Exception:
                # Proceed with the installation
                with AM("%s installation" % tool['name']):
                    tool['cli'].install(
                        os.path.dirname(Project.cloud_tools_bin_path)
                    )

    def ssh_key_gen(self, env, ssh_user, is_customer_key=False):
        # Build SSH key pair for POT
        if not is_customer_key:
            project_ssh_priv_key = os.path.join(
                self.project_path, "%s_%s_key" % (ssh_user, self.name)
            )
            project_ssh_pub_key = os.path.join(
                self.project_path, "%s_%s_key.pub" % (ssh_user, self.name)
            )
        else:
            project_ssh_priv_key = os.path.join(
                self.project_path, "%s_key" % ssh_user
            )
            project_ssh_pub_key = os.path.join(
                self.project_path, "%s_key.pub" % ssh_user
            )

        try:
            output = exec_shell([
                "ssh-keygen",
                "-q",
                "-t rsa",
                "-f %s" % project_ssh_priv_key,
                "-C \"\" -N \"\"",
            ])
            result = output.decode("utf-8")
            logging.debug("Command output:")
            for line in result.split("\n"):
                logging.debug(line)
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise ProjectError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

        ext_project_ssh_priv_key = project_ssh_priv_key + '.pem'
        os.rename(project_ssh_priv_key, ext_project_ssh_priv_key)
        if env.reference_architecture.startswith('EDB-Always-On'):
            shutil.copy(project_ssh_pub_key, ext_project_ssh_priv_key + '.pub')

        self.custom_ssh_keys[ssh_user] = dict(
            ssh_pub_key=project_ssh_pub_key,
            ssh_priv_key=ext_project_ssh_priv_key
        )

    def prepare_ssh(self, node_name):
        """
        Checks if a given node name exists in that project and returns its
        public address, SSH user and SSH priv. key path.
        """
        # Check if the machines have been provisioned when the provision step
        # is required
        cloud_vendors_provisioning = ['aws', 'azure', 'gcloud', 'aws-pot',
                                      'azure-pot', 'gcloud-pot']
        if self.env.cloud in cloud_vendors_provisioning:
            try:
                states = self.load_states()
            except Exception:
                states = {}
            status = states.get('terraform', 'UNKNOWN')
            if status != 'PROVISIONED':
                raise ProjectError('Machines not provisioned')

        # Get SSH user and key path from ansible vars.
        self._load_ansible_vars()
        ssh_user = self.ansible_vars['ssh_user']
        ssh_priv_key = self.ansible_vars['ssh_priv_key']

        # Read ansible inventory
        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )
        inventory_data = ansible.list_inventory(self.ansible_inventory)

        # Checking inventory entries
        for hostname, attrs in inventory_data['_meta']['hostvars'].items():
            if node_name == hostname.split('.')[0]:
                return (attrs['ansible_host'], ssh_user, ssh_priv_key)

        raise ProjectError("Node %s not found in the inventory" % node_name)

    def ssh(self, node_address, ssh_user, ssh_priv_key):
        """
        Open an interactive SSH connection to the node
        """
        os.system(' '.join([
            "ssh",
            "-i", ssh_priv_key,
            "%s@%s" % (ssh_user, node_address)
        ]))

    def get_ssh_keys(self):
        """
        Get a copy, into the current directory, of the SSH private keys (we can
        have 2 keys in the PoT case) and the ssh_config file.
        """
        files = list()
        # Check if the machines have been provisioned when the provision step
        # is required
        cloud_vendors_provisioning = ['aws', 'azure', 'gcloud', 'aws-pot',
                                      'azure-pot', 'gcloud-pot']
        if self.env.cloud in cloud_vendors_provisioning:
            try:
                states = self.load_states()
            except Exception:
                states = {}
            status = states.get('terraform', 'UNKNOWN')
            if status != 'PROVISIONED':
                raise ProjectError('Machines not provisioned')

        # Load terraform vars.
        self._load_terraform_vars()

        # Add the key used for the deployment
        files.append(self.terraform_vars['ssh_priv_key'])

        if self.env.cloud in ['aws-pot', 'azure-pot', 'gcloud-pot']:
            # In PoT, we add the project key too
            files.append(
                os.path.join(
                    self.project_path, '%s_key.pem' % self.name
                )
            )
        if os.path.exists(os.path.join(self.project_path, 'ssh_config')):
            # Add ssh_config to the list of the files to copy only if it exists
            files.append(
                os.path.join(self.project_path, 'ssh_config')
            )

        for file in files:
            with AM("Copying %s into the current directory" % file):
                shutil.copy(file, os.path.basename(file))

    """
    TPAexec related methods
    """
    def tpaexec_provision(self):
        self._load_ansible_vars()

        tpaexec = TPAexecCli(
            self.project_path,
            tpa_subscription_token=self.ansible_vars['tpa_subscription_token'],
            bin_path=self.ansible_vars['tpaexec_bin']
        )

        with AM("TPAexec relink execution"):
            tpaexec.relink()
        with AM("TPAexec provision execution"):
            tpaexec.provision()

    def tpaexec_deploy(self):
        self._load_ansible_vars()

        tpaexec = TPAexecCli(
            self.project_path,
            tpa_subscription_token=self.ansible_vars['tpa_subscription_token'],
            bin_path=self.ansible_vars['tpaexec_bin']
        )

        with AM("Executing tpaexec deploy"):
            tpaexec.deploy()
            tpa_pass_dir = os.path.join( self.project_path,
                                         'inventory/group_vars',
                                         'tag_Cluster_%s' % self.name,
                                         'secrets'
                                      )

            for pass_file in os.listdir(tpa_pass_dir):
                if not pass_file.endswith('_password.yml'):
                    continue
                username = pass_file.replace('_password.yml', '')
                tpaexec.tpa_password(username)

    """
    PoT related methods
    """
    def pot_configure(self, env):
        """
        Configure sub-comand for PoT environment
        """

        # Verify the tpaexec_bin and tpa_subscription_token based on architecture
        if env.reference_architecture.startswith('EDB-Always-On'):
            if not env.tpaexec_bin or not env.tpa_subscription_token:
                raise ProjectError(
                         "--tpaexec-bin and --tpaexec-subscription-token "
                         "are mandatory parameter for %s" % env.reference_architecture
                        )
        # Load specifications
        env.cloud_spec = self._load_cloud_specs(env)
        # Copy the PoT role in ansible project directory
        ansible_roles_path = os.path.join(self.project_path, "roles")
        ansible_pot_rte53_rm = os.path.join(self.project_path, "POT-Remove-Project-Route53.yml")
        tpaexec_hooks_path = os.path.join(self.project_path, "hooks")
        with AM("Copying PoT role code into %s" % ansible_roles_path):
            try:
                shutil.copytree(self.ansible_pot_role, ansible_roles_path)
            except Exception as e:
                raise ProjectError(str(e))

        with AM("Copying Route53 cleanup playbook code into %s" % ansible_pot_rte53_rm):
            try:
                shutil.copy(self.ansible_route53_remove, ansible_pot_rte53_rm)
            except Exception as e:
                raise ProjectError(str(e))

        if env.reference_architecture.startswith('EDB-Always-On'):
            with AM("Copying PoT TPAexec hooks code into %s" % tpaexec_hooks_path):
                try:
                    shutil.copytree(self.tpaexec_pot_hooks, tpaexec_hooks_path)
                except Exception as e:
                    raise ProjectError(str(e))

        with AM("Creating ssh keys for project"):
            _os = self.operating_system
            ssh_user = env.cloud_spec['available_os'][_os]['ssh_user']
            self.ssh_key_gen(env, ssh_user, False)

        with AM("Creating customer ssh keys for project"):
            self.ssh_key_gen(env, self.name, True)

        # Hook function called by Project.configure()
        # Transform Terraform templates
        self._transform_terraform_tpl()
        # Build the vars files for Terraform and Ansible
        self._build_terraform_vars_file(env)
        self._build_ansible_vars_file(env)
        # Build edb credential file
        self._save_edb_credentials(env)
        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()
        # Check Cloud Instance type and Image availability.
        self._check_instance_image(env)
        # Check tpaexec version
        if env.reference_architecture.startswith('EDB-Always-On'):
            tpaexec = TPAexecCli(
                        self.project_path,
                        tpa_subscription_token=env.tpa_subscription_token,
                        bin_path=env.tpaexec_bin
                      )
            tpaexec.check_version()

    def pot_provision(self, env):
        self._load_ansible_vars()

        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        with AM("Terraform project initialization"):
            self.update_state('terraform', 'INITIALIZATING')
            terraform.init()
            self.update_state('terraform', 'INITIALIZATED')

        with AM("Applying cloud resources creation"):
            self.update_state('terraform', 'PROVISIONING')
            terraform.apply(self.terraform_vars_file)
            self.update_state('terraform', 'PROVISIONED')

        # Checking instance availability
        cloud_cli = CloudCli(self.cloud, bin_path=self.cloud_tools_bin_path)
        # Load terraform variables
        self._load_terraform_vars()

        # inventory.yml and config.yml generation
        # Variables passed to template rendering functions
        render_vars = dict(
            reference_architecture=self.ansible_vars['reference_architecture'],
            cluster_name=self.ansible_vars['cluster_name'],
            pg_type=self.ansible_vars['pg_type'],
            pooler_local=self.terraform_vars['pooler_local'],
            pooler_type=self.terraform_vars['pooler_type'],
            replication_type=self.terraform_vars['replication_type'],
            ssh_priv_key=self.terraform_vars['ssh_priv_key'],
            ssh_user=self.terraform_vars['ssh_user']
        )
        # Ansible inventory.yml generation hook
        exec_hook(self, 'hook_inventory_yml', render_vars)
        # TPAexec config.yml generation hook
        exec_hook(self, 'hook_config_yml', render_vars)

        # Instances availability checking hook
        exec_hook(self, 'hook_instances_avaiblability', cloud_cli)

        if self.ansible_vars['reference_architecture'].startswith('EDB-Always-On'):
            self.tpaexec_provision()

        with AM("SSH configuration"):
            terraform.exec_add_host_sh()

    def pot_build_ansible_vars(self, env):
        """
        Build Ansible variables for the PoT environments
        """
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)

        os_spec = env.cloud_spec['available_os'][self.operating_system]
        pg_spec = env.cloud_spec['postgres_server']

        self.ansible_vars = {
            'tpaexec_bin': env.tpaexec_bin,
            'tpa_subscription_token': env.tpa_subscription_token,
            'reference_architecture': env.reference_architecture,
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
            'route53_session_token': env.route53_session_token,
            'project': self.name,
            'public_key': self.custom_ssh_keys[self.name]['ssh_pub_key'],
        }

        # Add configuration for pg_data and pg_wal accordingly to the
        # number of additional volumes
        if pg_spec['additional_volumes']['count'] > 0:
            self.ansible_vars.update(dict(pg_data='/pgdata/pg_data'))
        if pg_spec['additional_volumes']['count'] > 1:
            self.ansible_vars.update(dict(pg_wal='/pgwal/pg_wal'))

    def pot_deploy(self, no_install_collection, pre_deploy_ansible=None,
                   post_deploy_ansible=None, skip_main_playbook=False,
                   disable_pipelining=False):
        """
        Deployment method for the PoT environments
        """

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )

        # Load ansible vars
        self._load_ansible_vars()

        if self.ansible_vars['reference_architecture'].startswith('EDB-Always-On'):
            self.tpaexec_deploy()

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
            route53_session_token=self.ansible_vars['route53_session_token'],
            project=self.ansible_vars['project'],
            public_key=self.ansible_vars['public_key'],
            reference_architecture=self.ansible_vars['reference_architecture']
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
                    json.dumps(extra_vars),
                    disable_pipelining=disable_pipelining,
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
                    json.dumps(extra_vars),
                    disable_pipelining=disable_pipelining,
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
                    json.dumps(extra_vars),
                    disable_pipelining=disable_pipelining,
                )

        if not skip_main_playbook:
            # Display inventory informations
            self.display_inventory(inventory_data)

    def pot_display_inventory(self, inventory_data):
        """
        Display the inventory for PoT environments
        """
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

    def pot_destroy(self):
        """
        POT destroy method
        """
        terraform = TerraformCli(
            self.project_path, self.terraform_plugin_cache_path,
            bin_path=self.cloud_tools_bin_path
        )

        inventory_data = None
        ansible = AnsibleCli(
            self.project_path,
            bin_path=self.cloud_tools_bin_path
        )

        # Load ansible vars
        self._load_ansible_vars()

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
            route53_session_token=self.ansible_vars['route53_session_token'],
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

        try:
            states = self.load_states()
        except Exception:
            states = {}
        status = states.get('ansible', 'UNKNOWN')
        pot_rt53_path = os.path.join(self.project_path, 'POT-Remove-Project-Route53.yml')
        if status in ['DEPLOYED'] and os.path.exists(pot_rt53_path):
            with AM("Executing Route53 update playbook"):
                ansible.run_playbook(
                    self.cloud,
                    self.ansible_vars['ssh_user'],
                    self.ansible_vars['ssh_priv_key'],
                    self.ansible_inventory,
                    'POT-Remove-Project-Route53.yml',
                    json.dumps(extra_vars),
                    disable_pipelining=True,
                )

        with AM("Destroying cloud resources"):
            self.update_state('terraform', 'DESTROYING')
            terraform.destroy(self.terraform_vars_file)
            self.update_state('terraform', 'DESTROYED')
            self.update_state('ansible', 'UNKNOWN')

    def pot_update_route53_key(self, n_route53_access_key, n_route53_secret, n_route53_session_token):
        with AM("Updating route53 key, secret and session-token"):
            self._load_ansible_vars()
            self.ansible_vars['route53_access_key'] = n_route53_access_key
            self.ansible_vars['route53_secret'] = n_route53_secret
            self.ansible_vars['route53_session_token'] = n_route53_session_token
            self._save_ansible_vars()
