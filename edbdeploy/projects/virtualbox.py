import errno
from ipaddress import ip_address
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
from ..spec.virtualbox import VirtualBoxSpec
from ..specifications import default, merge
from ..virtualbox import VirtualBoxCli
from ..render import build_vagrantfile


class VirtualBoxProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(VirtualBoxProject, self).__init__('virtualbox', name, env, bin_path)

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()

        self._build_ansible_vars_file(env)
        self._build_vagrant_vars(env)
        # Copy VirtualBox Vagrant Config File into project dir.
        self._copy_virtualbox_configfiles(env)

    def hook_instances_availability(self, cloud_cli):
        # Update before committing with
        # projects_root_path
        self.vagrant_project_path = os.path.join(
            self.projects_root_path,
            'virtualbox',
            self.name
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        vagrant = VirtualBoxCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.vagrant_project_path, bin_path=self.cloud_tools_bin_path
        )
        with AM("Provisioning Virtual Machines"):
            vagrant.up()
        # Build ip address list for virtualbox deployment
        with AM("Build VirtualBox Ansible IP addresses"):
            # Assigning Reference Architecture
            self.env.reference_architecture = \
                self.ansible_vars['reference_architecture']

            # Load specifications
            self.env.cloud_spec = self._load_cloud_specs(self.env)

            # Build virtualbox Ansible IP addresses
            self._build_virtualbox_ips(self.env)

    def check_avail_memory(self, mem_size):
        avail_memory = psutil.virtual_memory().available / (1024.0 ** 3)
        #Converting megabytes to gigabytes
        mem_size = int(mem_size) / 1024
        if self.env.reference_architecture == 'EDB-RA-1' and avail_memory < mem_size * 3:
            raise ValueError("For EDB-RA-1 you must have at least %s GB of free memory. "
            "Try lowering your memory-size." % (mem_size * 3))
        if self.env.reference_architecture == 'EDB-RA-2' and avail_memory < mem_size * 5:
            raise ValueError("For EDB-RA-2 you must have at least %s GB of free memory. "
            "Try lowering your memory-size." % (mem_size * 5))
        if self.env.reference_architecture == 'EDB-RA-3' and avail_memory < mem_size * 8:
            raise ValueError("For EDB-RA-3 you must have at least %s GB of free memory. "
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
        self.vagrant_project_path = os.path.join(
            self.projects_root_path,
            'virtualbox',
            self.name
        )
        # Check only Python3 version when working with virtualbox deployment
        vm = VirtualBoxCli(
            'dummy', self.name, self.cloud, 0, 0, self.vagrant_project_path,
            bin_path=self.cloud_tools_bin_path
        )
        vm.python_check_version()
        vm.vagrant_check_version()

    def provision(self, env):
        # Overload Project.provision()
        self._load_ansible_vars()

        # Update before committing with
        # projects_root_path
        self.vagrant_project_path = os.path.join(
            self.projects_root_path,
            'virtualbox',
            self.name,
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        vagrant = VirtualBoxCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.vagrant_project_path, bin_path=self.cloud_tools_bin_path
        )
        with AM("Provisioning Virtual Machines"):
            vagrant.up()

        # Build ip address list for VirtualBox deployment
        with AM("Build VirtualBox Ansible IP addresses"):
            # Assigning Reference Architecture
            env.reference_architecture = \
                self.ansible_vars['reference_architecture']

            # Load specifications
            cloud_spec = self._load_cloud_specs(env)
            defaults = default(cloud_spec)
            user_spec = self._load_user_spec(env)

            # Generate dbt-2 client and driver specs on the fly as it depends on
            # how many of each are desired.
            if 'dbt2_client' in user_spec and \
                    'count' in user_spec['dbt2_client']:
                for i in range(user_spec['dbt2_client']['count']):
                    name = 'dbt2_client_' + str(i)
                    user_spec[name] = dict()
                    user_spec[name]['name'] = name
                    user_spec[name]['public_ip'] = None
                    user_spec[name]['private_ip'] = None
                    cloud_spec[name] = dict()
                    cloud_spec[name]['name'] = name
                    cloud_spec[name]['public_ip'] = None
                    cloud_spec[name]['private_ip'] = None
                    defaults[name] = dict()
                    defaults[name]['name'] = name
                    defaults[name]['public_ip'] = None
                    defaults[name]['private_ip'] = None

            if 'dbt2_driver' in user_spec and \
                    'count' in user_spec['dbt2_driver']:
                for i in range(user_spec['dbt2_driver']['count']):
                    name = 'dbt2_driver_' + str(i)
                    user_spec[name] = dict()
                    user_spec[name]['name'] = name
                    user_spec[name]['public_ip'] = None
                    user_spec[name]['private_ip'] = None
                    cloud_spec[name] = dict()
                    cloud_spec[name]['name'] = name
                    cloud_spec[name]['public_ip'] = None
                    cloud_spec[name]['private_ip'] = None
                    defaults[name] = dict()
                    defaults[name]['name'] = name
                    defaults[name]['public_ip'] = None
                    defaults[name]['private_ip'] = None
            env.cloud_spec = merge(user_spec, cloud_spec, defaults)

            # Build VirtualBox Ansible IP addresses
            self._build_virtualbox_ips(env)

        # Build inventory file for VirtualBox deployment
        with AM("Build Ansible inventory file %s" % self.ansible_inventory):
            self._build_ansible_inventory(env)

    def destroy(self):
        # Overload Project.destroy()
        self._load_ansible_vars()
        # Update before committing with
        # projects_root_path
        self.vagrant_project_path = os.path.join(
            self.projects_root_path,
            'virtualbox',
            self.name
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        vagrant = VirtualBoxCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.vagrant_project_path, bin_path=self.cloud_tools_bin_path
        )
        with AM("Destroying cloud resources"):
            vagrant.destroy()

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
        """
        Build Ansible variables for VirtualBox deployment.
        """
        # Fetch EDB repo. username and password
        r = re.compile(r"^([^:]+):(.+)$")
        m = r.search(env.edb_credentials)
        edb_repo_username = m.group(1)
        edb_repo_password = m.group(2)
        # VirtualBox and Vagrant ssh_user and ssh_pass is: 'vagrant'
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
    
    def _load_user_spec(self, env):
        if os.path.exists(os.path.join(self.project_path, "spec.json")):
            return self._load_spec_file(os.path.join(self.project_path,
                                                "spec.json"))
        else:
            return default(VirtualBoxSpec.get(env.reference_architecture))

    def _build_vagrant_vars(self, env):
        """
        Build Vagrantfile variables for jinja2 template
        Templates available inside of edbdeploy/data/templates
        """
        user_spec = self._load_user_spec(env)
        os_image = user_spec['available_os'][env.operating_system] \
            .get('image', 'mwedb/rockylinux8')
        ip = ip_address(user_spec['ipv4'])
        self.vagrant_vars = {
            'mem_size': env.mem_size,
            'cpu_count': env.cpu_count,
            'image_name': os_image,
            'image_url': '',
            'vms': {}
        }
        
        # Assign ip address for virtual machines
        self.vagrant_vars['vms']['pem'] = { 'ip': ip }
        ip += 1
        self.vagrant_vars['vms']['barman'] = { 'ip': ip }
        ip += 1
        self.vagrant_vars['vms']['primary'] = { 'ip': ip }
        ip += 1
        if self.ansible_vars['reference_architecture'] in ['EDB-RA-2', 'EDB-RA-3']:
            for i in range(2, 4):
                self.vagrant_vars['vms'][f"standby{i}"] = { 'ip': ip }
                ip += 1
        if self.ansible_vars['reference_architecture'] in ['EDB-RA-3']:
            for i in  range(1, 4):
                self.vagrant_vars['vms'][f"pgpool{i}"] = { 'ip': ip }
                ip += 1
        for i in range(env.cloud_spec['dbt2_client']['count']):
            self.vagrant_vars['vms'][f'dbt2client{i}'] = { 'ip': ip }
            ip += 1
        for i in range(env.cloud_spec['dbt2_driver']['count']):
            self.vagrant_vars['vms'][f'dbt2driver{i}'] = { 'ip': ip }
            ip += 1

    def _build_virtualbox_ips(self, env):
        """
        Build IP Address list for VirtualBox deployment.
        """

        try:
            output = exec_shell(
                [
                    self.bin("vagrant"),
                    "ssh",
                    "pem",
                    "-c",
                    "\"ip address",
                    "show eth1", 
                    "|",
                    "grep",
                    "'inet '",
                    "|",
                    "sed",
                    "-e",
                    "'s/^.*inet //' -e 's/\/.*$//'\""
                ],
                environ=self.environ,
                cwd=self.vagrant_project_path
            )
            result = output.decode("utf-8").split('\n')
            result[0] = result[0].strip()
            env.cloud_spec['pem_server_1']['public_ip'] = result[0]
            env.cloud_spec['pem_server_1']['private_ip'] = result[0]
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                ("Failed to obtain VirtualBox Instance IP Address for: %s, please "
                 "check the logs for details.")
                % env.cloud_spec['pem_server_1']['name']
            )

        try:
            output = exec_shell(
                [
                    self.bin("vagrant"),
                    "ssh",
                    "barman",
                    "-c",
                    "\"ip address",
                    "show eth1", 
                    "|",
                    "grep",
                    "'inet '",
                    "|",
                    "sed",
                    "-e",
                    "'s/^.*inet //' -e 's/\/.*$//'\""
                ],
                environ=self.environ,
                cwd=self.vagrant_project_path
            )
            result = output.decode("utf-8").split('\n')
            result[0] = result[0].strip()
            env.cloud_spec['backup_server_1']['public_ip'] = result[0]
            env.cloud_spec['backup_server_1']['private_ip'] = result[0]
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                ("Failed to obtain VirtualBox Instance IP Address for: %s, please "
                 "check the logs for details.")
                % env.cloud_spec['backup_server_1']['name']
            )

        try:
            output = exec_shell(
                [
                    self.bin("vagrant"),
                    "ssh",
                    "primary",
                    "-c",
                    "\"ip address",
                    "show eth1", 
                    "|",
                    "grep",
                    "'inet '",
                    "|",
                    "sed",
                    "-e",
                    "'s/^.*inet //' -e 's/\/.*$//'\""
                ],
                environ=self.environ,
                cwd=self.vagrant_project_path
            )
            result = output.decode("utf-8").split('\n')
            result[0] = result[0].strip()
            env.cloud_spec['postgres_server_1']['public_ip'] = result[0]
            env.cloud_spec['postgres_server_1']['private_ip'] = result[0]
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                ("Failed to obtain VirtualBox Instance IP Address for: %s, please "
                 "check the logs for details.")
                % env.cloud_spec['postgres_server_1']['name']
            )

        if env.reference_architecture in ['EDB-RA-2', 'EDB-RA-3']:
            for i in range(2, 4):
                name = f"standby{i}"
                try:
                    output = exec_shell(
                        [
                            self.bin("vagrant"),
                                "ssh",
                                name,
                                "-c",
                                "\"ip address",
                                "show eth1", 
                                "|",
                                "grep",
                                "'inet '",
                                "|",
                                "sed",
                                "-e",
                                "'s/^.*inet //' -e 's/\/.*$//'\""
                        ],
                        environ=self.environ,
                        cwd=self.vagrant_project_path
                    )
                    result = output.decode("utf-8").split('\n')
                    result[0] = result[0].strip()
                    env.cloud_spec['postgres_server_%s' % i]['public_ip'] = result[0]  # noqa
                    env.cloud_spec['postgres_server_%s' % i]['private_ip'] = result[0]  # noqa
                except Exception as e:
                    logging.error("Failed to execute the command")
                    logging.error(e)
                    raise CliError(
                        ("Failed to obtain VirtualBox Instance IP Address for: %s,"
                         "please check the logs for details.")
                        % env.cloud_spec['postgres_server_%s' % i]['name']
                    )
        if env.reference_architecture == 'EDB-RA-3':
            for i in range(1, 4):
                try:
                    name = f"pgpool{i}"
                    output = exec_shell(
                        [
                            self.bin("vagrant"),
                                "ssh",
                                name,
                                "-c",
                                "\"ip address",
                                "show eth1", 
                                "|",
                                "grep",
                                "'inet '",
                                "|",
                                "sed",
                                "-e",
                                "'s/^.*inet //' -e 's/\/.*$//'\""
                        ],
                        environ=self.environ,
                        cwd=self.vagrant_project_path
                    )
                    result = output.decode("utf-8").split('\n')
                    result[0] = result[0].strip()
                    env.cloud_spec['pooler_server_%s' % i]['public_ip'] = result[0]  # noqa
                    env.cloud_spec['pooler_server_%s' % i]['private_ip'] = result[0]  # noqa
                except Exception as e:
                    logging.error("Failed to execute the command")
                    logging.error(e)
                    raise CliError(
                        ("Failed to obtain VirtualBox Instance IP Address for: %s,"
                         "please check the logs for details.")
                        % env.cloud_spec['pooler_server_%s' % i]['name']
                    )
        for i in range(env.cloud_spec['dbt2_client']['count']):
            name = f"dbt2client{i}"
            try:
                output = exec_shell(
                    [
                        self.bin("vagrant"),
                            "ssh",
                            name,
                            "-c",
                            "\"ip address",
                            "show eth1",
                            "|",
                            "grep",
                            "'inet '",
                            "|",
                            "sed",
                            "-e",
                            "'s/^.*inet //' -e 's/\/.*$//'\""
                    ],
                    environ=self.environ,
                    cwd=self.vagrant_project_path
                )
                result = output.decode("utf-8").split('\n')
                result[0] = result[0].strip()
                env.cloud_spec[name]['public_ip'] = result[0]  # noqa
                env.cloud_spec[name]['private_ip'] = result[0]  # noqa
            except Exception as e:
                logging.error("Failed to execute the command")
                logging.error(e)
                raise CliError(
                    ("Failed to obtain VirtualBox Instance IP Address for: %s,"
                        "please check the logs for details.")
                    % name
                )
        for i in range(env.cloud_spec['dbt2_driver']['count']):
            name = f"dbt2_driver_{i}"
            try:
                output = exec_shell(
                    [
                        self.bin("vagrant"),
                            "ssh",
                            f"dbt2driver{i}",
                            "-c",
                            "\"ip address",
                            "show eth1",
                            "|",
                            "grep",
                            "'inet '",
                            "|",
                            "sed",
                            "-e",
                            "'s/^.*inet //' -e 's/\/.*$//'\""
                    ],
                    environ=self.environ,
                    cwd=self.vagrant_project_path
                )
                result = output.decode("utf-8").split('\n')
                result[0] = result[0].strip()
                env.cloud_spec[name]['public_ip'] = result[0]  # noqa
                env.cloud_spec[name]['private_ip'] = result[0]  # noqa
            except Exception as e:
                logging.error("Failed to execute the command")
                logging.error(e)
                raise CliError(
                    ("Failed to obtain VirtualBox Instance IP Address for: %s,"
                        "please check the logs for details.")
                    % name
                )

    def _copy_virtualbox_configfiles(self, env):
        """
        Create the user specification, if defined, Vagrantfile and Ansible
        playbook in project directory.
        """
        if getattr(env, 'spec_file', False):
            shutil.copy(env.spec_file.name,
                        os.path.join(self.project_path, "spec.json"))

        self.vagrantfile = os.path.join(self.project_path, "Vagrantfile")
        fromplaybookfile = os.path.join(self.ansible_share_path, "%s.yml" % self.ansible_vars['reference_architecture'])
        playbookfile = os.path.join(self.project_path, "playbook.yml")

        with AM(f"Copying playbook file into {playbookfile}"):
            try:
                shutil.copy(fromplaybookfile, playbookfile)
            except IOError as e:
                if e.errno != errno.ENOENT:
                    raise
                os.makedirs(os.path.dirname(self.vagrantfile))
                shutil.copy(fromplaybookfile, playbookfile)

        with AM(f"Building Vagrantfile into {self.vagrantfile}"):
            build_vagrantfile(self.vagrantfile, self.vagrant_vars)

    def remove(self):
        # Overload Project.remove()
        self._load_ansible_vars()
        # Update before committing with projects_root_path
        self.vagrant_project_path = os.path.join(
            self.projects_root_path,
            'virtualbox/',
            self.name
        )
        mem_size = self.ansible_vars['mem_size']
        cpu_count = self.ansible_vars['cpu_count']
        vagrant = VirtualBoxCli(
            self.cloud, self.name, self.cloud, mem_size, cpu_count,
            self.vagrant_project_path, bin_path=self.cloud_tools_bin_path
        )
        # Counts images currently running in project folder
        if vagrant.count_resources() > 0:
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
                vagrant_project_path = project.project_path
                vagrant = VirtualBoxCli(
                    cloud, project.name, cloud, ansible_vars['mem_size'],
                    ansible_vars['cpu_count'], vagrant_project_path,
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
                    vagrant.vagrant_machine_status(),
                    # Returns an integer of the number of images running in the
                    # project
                    str(vagrant.count_resources()),
                    states.get('ansible', 'UNKNOWN')
                ])

            Project.display_table(headers, rows)

        except OSError as e:
            msg = "Unable to list projects in %s" % projects_path
            logging.error(msg)
            logging.exception(str(e))
            raise ProjectError(msg)
