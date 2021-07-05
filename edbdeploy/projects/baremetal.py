import getpass
import os
import re
import shutil

from ..action import ActionManager as AM
from ..ansible import AnsibleCli
from ..project import Project


class BaremetalProject(Project):
    def __init__(self, name, env, bin_path=None):
        super(BaremetalProject, self).__init__(
            'baremetal', name, env, bin_path
        )

    def hook_post_configure(self, env):
        # Hook function called by Project.configure()
        # Build the vars files for Ansible
        self._build_ansible_vars_file(env)
        # Copy Ansible playbook into project dir.
        self._copy_ansible_playbook()
        with AM("Build Ansible inventory file %s" % self.ansible_inventory):
            self._build_ansible_inventory(env)

    def create(self):
        # Overload Project.create() by creating project directory only
        with AM("Creating project directory %s" % self.project_path):
            os.makedirs(self.project_path)

    def check_versions(self):
        # Overload Project.check_versions()
        # Check Ansible version
        ansible = AnsibleCli('dummy', bin_path=self.cloud_tools_bin_path)
        ansible.check_version()

    def _build_ansible_vars(self, env):
        # Overload Project._build_ansible_vars()
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
            'use_hostname': env.use_hostname,
        }

        # Add configuration for pg_data and pg_wal
        if env.cloud_spec['pg_data'] is not None:
            self.ansible_vars.update(dict(pg_data=env.cloud_spec['pg_data']))
        if env.cloud_spec['pg_wal'] is not None:
            self.ansible_vars.update(dict(pg_wal=env.cloud_spec['pg_wal']))

    def _load_terraform_vars(self):
        # Overload Project._load_terraform_vars()
        pass

    def remove(self):
        # Overload Project.remove()
        if os.path.exists(self.log_file):
            with AM("Removing log file %s" % self.log_file):
                os.unlink(self.log_file)
        with AM("Removing project directory %s" % self.project_path):
            shutil.rmtree(self.project_path)
