import errno
import json
import logging
import os
import re
import shutil
import psutil

from ..action import ActionManager as AM
from ..ansible import AnsibleCli
from ..errors import CliError, ProjectError
from ..project import Project
from ..system import exec_shell
from ..vmware import VMWareCli


class VMwareProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(VMwareProject, self).__init__('vmware', name, env, bin_path)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Build the vars files for Ansible
        self._build_ansible_vars_file(env)
        # Copy VMWare Mech Config File into project dir.
        self._copy_vmware_configfiles()

    def hook_instances_availability(self, cloud_cli):
        # Update before committing with
        # projects_root_path
        self.mech_project_path = os.path.join(
            self.projects_root_path,
            'vmware',
            self.name
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        mech = VMWareCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.mech_project_path, bin_path=self.cloud_tools_bin_path
        )
        with AM("Checking instances availability"):
            mech.up()
        # Build ip address list for vmware deployment
        with AM("Build VMWare Ansible IP addresses"):
            # Assigning Reference Architecture
            self.env.reference_architecture = \
                self.ansible_vars['reference_architecture']

            # Load specifications
            self.env.cloud_spec = self._load_cloud_specs(self.env)

            # Build VMWare Ansible IP addresses
            self._build_vmware_ips(self.env)

    def check_avail_memory(self, mem_size):
        avail_memory = psutil.virtual_memory().available / (1024.0 ** 3)
        #Converting megabytes to gigabytes
        mem_size = int(mem_size) / 1024
        if self.env.reference_architecture == 'EDB-RA-1' and avail_memory < mem_size * 3:
            raise ValueError("For EDB-RA-1 you must have at least %s, GB of free memory. "
            "Try lowering your memory-size." % (mem_size * 3))
        if self.env.reference_architecture == 'EDB-RA-2' and avail_memory < mem_size * 5:
            raise ValueError("For EDB-RA-2 you must have at least %s, GB of free memory. "
            "Try lowering your memory-size." % (mem_size * 5))
        if self.env.reference_architecture == 'EDB-RA-3' and avail_memory < mem_size * 8:
            raise ValueError("For EDB-RA-3 you must have at least %s, GB of free memory. "
            "Try lowering your memory-size." % (mem_size * 8))

    def create(self):
        # Overload Project.create() by creating project directory

        # Checking if there is enough free memory to create the number of servers
        # corresponding to the EDB reference architecture before creating project
        self.check_avail_memory(self.env.mem_size)
        with AM("Creating project directory %s" % self.project_path):
            os.makedirs(self.project_path)

    def check_versions(self):
        # Overload Project.check_versions()
        # Check Ansible version
        ansible = AnsibleCli('dummy', bin_path=self.cloud_tools_bin_path)
        ansible.check_version()

        # Update before committing with
        # projects_root_path
        self.mech_project_path = os.path.join(
            self.projects_root_path,
            'vmware',
            self.name
        )
        # Check only Python3 version when working with vmware deployment
        vm = VMWareCli(
            'dummy', self.name, self.cloud, 0, 0, self.mech_project_path,
            bin_path=self.cloud_tools_bin_path
        )
        vm.python_check_version()
        vm.vagrant_check_version()
        vm.mech_check_version()

    def provision(self, env):
        # Overload Project.provision()
        self._load_ansible_vars()

        # Update before committing with
        # projects_root_path
        self.mech_project_path = os.path.join(
            self.projects_root_path,
            'vmware',
            self.name,
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        mech = VMWareCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.mech_project_path, bin_path=self.cloud_tools_bin_path
        )
        with AM("Provisioning Virtual Machines"):
            mech.up()

        # Build ip address list for vmware deployment
        with AM("Build VMWare Ansible IP addresses"):
            # Assigning Reference Architecture
            env.reference_architecture = \
                self.ansible_vars['reference_architecture']

            # Load specifications
            env.cloud_spec = self._load_cloud_specs(env)

            # Build VMWare Ansible IP addresses
            self._build_vmware_ips(env)

        # Build inventory file for vmware deployment
        with AM("Build Ansible inventory file %s" % self.ansible_inventory):
            self._build_ansible_inventory(env)

    def destroy(self):
        # Overload Project.destroy()
        self._load_ansible_vars()
        # Update before committing with
        # projects_root_path
        self.mech_project_path = os.path.join(
            self.projects_root_path,
            'vmware',
            self.name
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        mech = VMWareCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.mech_project_path, bin_path=self.cloud_tools_bin_path
        )
        with AM("Destroying cloud resources"):
            mech.destroy()

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        """
        Build Ansible variables for vmware deployment.
        """
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)
        # VMWare and Vagrant ssh_user and ssh_pass is: 'vagrant'
        ssh_user = 'vagrant'
        ssh_pass = 'vagrant'
        operating_system = ''
        if env.operating_system == 'RockyLinux8':
            operating_system = 'r8'

        self.ansible_vars = {
            'reference_architecture': env.reference_architecture,
            'cluster_name': self.name,
            'pg_type': env.postgres_type,
            'pg_version': env.postgres_version,
            'repo_username': edb_repo_username,
            'repo_password': edb_repo_password,
            'mem_size': env.mem_size,
            'cpu_count': env.cpu_count,
            'operating_system': operating_system,
            'ssh_user': ssh_user,
            'ssh_pass': ssh_pass,
            'ssh_priv_key': self.ssh_priv_key,
            'efm_version': env.efm_version,
            'use_hostname': env.use_hostname,
        }

    def _build_vmware_ips(self, env):
        """
        Build IP Address list for vmware deployment.
        """
        # Load specifications
        env.cloud_spec = self._load_cloud_specs(env)

        try:
            output = exec_shell(
                [
                    self.bin("mech"),
                    "ip",
                    "%s" % env.cloud_spec['pem_server_1']['name']
                ],
                environ=self.environ,
                cwd=self.mech_project_path
            )
            result = output.decode("utf-8").split('\n')
            env.cloud_spec['pem_server_1']['public_ip'] = result[0]
            env.cloud_spec['pem_server_1']['private_ip'] = result[0]
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                ("Failed to obtain VMWare Instance IP Address for: %s, please "
                 "check the logs for details.")
                % env.cloud_spec['pem_server_1']['name']
            )

        try:
            output = exec_shell(
                [
                    self.bin("mech"),
                    "ip",
                    "%s" % env.cloud_spec['backup_server_1']['name']
                ],
                environ=self.environ,
                cwd=self.mech_project_path
            )
            result = output.decode("utf-8").split('\n')
            env.cloud_spec['backup_server_1']['public_ip'] = result[0]
            env.cloud_spec['backup_server_1']['private_ip'] = result[0]
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                ("Failed to obtain VMWare Instance IP Address for: %s, please "
                 "check the logs for details.")
                % env.cloud_spec['backup_server_1']['name']
            )

        try:
            output = exec_shell(
                [
                    self.bin("mech"),
                    "ip",
                    "%s" % env.cloud_spec['postgres_server_1']['name']
                ],
                environ=self.environ,
                cwd=self.mech_project_path
            )
            result = output.decode("utf-8").split('\n')
            env.cloud_spec['postgres_server_1']['public_ip'] = result[0]
            env.cloud_spec['postgres_server_1']['private_ip'] = result[0]
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                ("Failed to obtain VMWare Instance IP Address for: %s, please "
                 "check the logs for details.")
                % env.cloud_spec['postgres_server_1']['name']
            )

        if env.reference_architecture in ['EDB-RA-2', 'EDB-RA-3']:
            pem1 = env.cloud_spec['pem_server_1']
            pg1 = env.cloud_spec['postgres_server_1']
            backup1 = env.cloud_spec['backup_server_1']
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
                                    'pem_server_private_ip': pem1['private_ip'],  # noqa
                                    'barman': True,
                                    'barman_server_private_ip': backup1['private_ip'],  # noqa
                                    'barman_backup_method': 'postgres',
                                }
                            }
                        }
                    }
                }
            }
            inventory['all']['children'].update({
                'standby': {
                    'hosts': {}
                }
            })
            for i in range(2, 4):
                try:
                    output = exec_shell(
                        [
                            self.bin("mech"),
                            "ip",
                            env.cloud_spec['postgres_server_%s' % i]['name']
                        ],
                        environ=self.environ,
                        cwd=self.mech_project_path
                    )
                    result = output.decode("utf-8").split('\n')
                    env.cloud_spec['postgres_server_%s' % i]['public_ip'] = result[0]  # noqa
                    env.cloud_spec['postgres_server_%s' % i]['private_ip'] = result[0]  # noqa
                except Exception as e:
                    logging.error("Failed to execute the command")
                    logging.error(e)
                    raise CliError(
                        ("Failed to obtain VMWare Instance IP Address for: %s,"
                         "please check the logs for details.")
                        % env.cloud_spec['postgres_server_%s' % i]['name']
                    )
        if env.reference_architecture == 'EDB-RA-3':
            inventory['all']['children'].update({
                'pgpool2': {
                    'hosts': {}
                }
            })
            for i in range(1, 4):
                try:
                    output = exec_shell(
                        [
                            self.bin("mech"),
                            "ip",
                            env.cloud_spec['pooler_server_%s' % i]['name']
                        ],
                        environ=self.environ,
                        cwd=self.mech_project_path
                    )
                    result = output.decode("utf-8").split('\n')
                    env.cloud_spec['pooler_server_%s' % i]['public_ip'] = result[0]  # noqa
                    env.cloud_spec['pooler_server_%s' % i]['private_ip'] = result[0]  # noqa
                except Exception as e:
                    logging.error("Failed to execute the command")
                    logging.error(e)
                    raise CliError(
                        ("Failed to obtain VMWare Instance IP Address for: %s,"
                         "please check the logs for details.")
                        % env.cloud_spec['pooler_server_%s' % i]['name']
                    )

    def _copy_vmware_configfiles(self):
        """
        Copy reference architecture Mech Config file into project directory.
        """
        # Un-comment the self.vmware_share_path once the entire commit has been
        # completed
        frommechfile = os.path.join(
            self.vmware_share_path,
            "%s-%s" % (
                self.ansible_vars['operating_system'],
                self.ansible_vars['reference_architecture']
            )
        )
        self.mechfile = os.path.join(self.project_path, "Mechfile")
        fromplaybookfile = os.path.join(self.vmware_share_path, "playbook.yml")
        playbookfile = os.path.join(self.project_path, "playbook.yml")

        with AM("Copying Mech Config files into %s" % self.mechfile):
            # Mechfile
            try:
                shutil.copy(frommechfile, self.mechfile)
            except IOError as e:
                if e.errno != errno.ENOENT:
                    raise
                os.makedirs(os.path.dirname(self.mechfile))
                shutil.copy(frommechfile, self.mechfile)
            # Playbook File
            try:
                shutil.copy(fromplaybookfile, playbookfile)
            except IOError as e:
                if e.errno != errno.ENOENT:
                    raise
                os.makedirs(os.path.dirname(self.mechfile))
                shutil.copy(fromplaybookfile, playbookfile)

    def remove(self):
        # Overload Project.remove()
        self._load_ansible_vars()
        # Update before committing with projects_root_path
        self.mech_project_path = os.path.join(
            self.projects_root_path,
            'vmware/',
            self.name
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        mech = VMWareCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.mech_project_path, bin_path=self.cloud_tools_bin_path
        )
        # Counts images currently running in project folder
        if mech.count_resources() > 0:
            raise ProjectError(
                "Some cloud resources seem to be still present for this "
                "project, please destroy them with the 'destroy' sub-command"
            )

        if os.path.exists(self.log_file):
            with AM("Removing log file %s" % self.log_file):
                os.unlink(self.log_file)
        with AM("Removing project directory %s" % self.project_path):
            shutil.rmtree(self.project_path)

    @staticmethod
    def list(cloud):
        # Override Project.list()
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

                data = open(project.project_path + "/ansible_vars.json", "r")
                ansible_vars = json.load(data)
                mech_project_path = project.project_path
                mech = VMWareCli(
                    cloud, project.name, cloud, ansible_vars['mem_size'],
                    ansible_vars['cpu_count'], mech_project_path,
                    bin_path=project.cloud_tools_bin_path
                )

                try:
                    states = project.load_states()
                except Exception:
                    states = {}

                rows.append([
                    project.name,
                    project.project_path,
                    # Counts the number of machines running in the project, if
                    # it is greater than 0 than it is PROVISIONED otherwise it
                    # is destroyed
                    mech.mech_machine_status(),
                    # Returns an integer of the number of images running in the
                    # project
                    str(mech.count_resources()),
                    states.get('ansible', 'UNKNOWN')
                ])

            Project.display_table(headers, rows)

        except OSError as e:
            msg = "Unable to list projects in %s" % projects_path
            logging.error(msg)
            logging.exception(str(e))
            raise ProjectError(msg)
