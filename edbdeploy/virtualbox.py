import json
import logging
import os
import re
from subprocess import CalledProcessError
import textwrap

from .errors import VirtualBoxCliError, CliError
from .installation import build_tmp_install_script, execute_install_script
from .system import exec_shell_live, exec_shell
from . import check_version, to_str


class VirtualBoxCli:

    def __init__(self, dir, name, cloud, mem_size, cpu_count, vagrant_project_path, bin_path=None):
        self.dir = dir
        self.environ = os.environ
        self.name = name
        self.cloud = cloud
        self.mem_size = mem_size
        self.cpu_count = cpu_count
        self.vagrant_project_path = vagrant_project_path

        # Python supported versions interval
        self.python_min_version = (3, 8, 0)
        self.python_max_version = (9, 9, 9)
        # Vagrant supported versions interval
        self.vagrant_min_version = (2, 0, 0)
        self.vagrant_max_version = (9, 9, 9)
        # Path to look up for executable
        self.bin_path = None
        # Force Ansible binary path if bin_path exists and contains
        # ansible file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'python')):
                self.bin_path = bin_path

    def python_check_version(self):
        """
        Verify python version, based on the interval formed by python_min_version and
        python_max_version.
        Python version is fetched using the command: python3 --version
        """
        # note: we do not raise any AnsibleCliError from this function because
        # AnsibleCliError are used to trigger stuffs when they are catched. In
        # this case, we do not want trigger anything if something fails.
        try:
            output = exec_shell([
                self.bin("python3"),
                "--version"
            ])
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CliError(
                "Python3 executable seems to be missing. Please install it or "
                "check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^Python ([0-9]+)\.([0-9]+)\.([0-9]+)$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise CliError("Unable to parse Python3 version")

        logging.info("Python3 version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.python_min_version,
                             self.python_max_version):
            raise CliError(
                "Python3 version %s not supported, must be between %s and %s"
                % (to_str(version), to_str(self.python_min_version),
                   to_str(self.python_max_version)))

    def vagrant_check_version(self):
        """
        Verify vagrant version, based on the interval formed by vagrant_min_version and
        vagrant_max_version.
        Vagrant version is fetched using the command: vagrant --version
        """
        # note: we do not raise any AnsibleCliError from this function because
        # AnsibleCliError are used to trigger stuffs when they are catched. In
        # this case, we do not want trigger anything if something fails.
        try:
            output = exec_shell([
                self.bin("vagrant"),
                "--version"
            ])
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CliError(
                "Vagrant executable seems to be missing. Please install it or "
                "check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^Vagrant ([0-9]+)\.([0-9]+)\.([0-9]+)$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise CliError("Unable to parse Vagrant version")

        logging.info("Vagrant version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.vagrant_min_version,
                             self.vagrant_max_version):
            raise CliError(
                "Vagrant version %s not supported, must be between %s and %s"
                % (to_str(version), to_str(self.vagrant_min_version),
                   to_str(self.vagrant_max_version)))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def up(self):
        try:
            rc = exec_shell_live(
                [   self.bin("vagrant"),
                    "up",
                ],
                environ=self.environ,
                cwd=self.vagrant_project_path
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                "Failed to provision VirtualBox Instances, please check the logs for details."
            )

    def destroy(self):
        try:
            rc = exec_shell_live(
                [   
                    
                    self.bin("vagrant"),
                    "destroy",
                    "--force",
                ],
                environ=self.environ,
                cwd=self.vagrant_project_path
            )
            
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                "Failed to destroy VirtualBox Instances, please check the logs for details."
            )

    def count_resources(self):
        try:     
            # Uses vagrant status see all running instances within,
            # grep gets all instances with started as state which means its on, 
            # wc returns a count of listed machines with 'running'
            output = exec_shell(
                [
                    self.bin("vagrant"),
                    "status",
                    "|",
                    self.bin("grep"),
                    "running",
                    "|",
                    self.bin("wc"),
                    "-l" 
                ],
                environ=self.environ,
                cwd=self.vagrant_project_path
            )
            result = output.decode("utf-8").strip()
            return int(result)
            
            
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                "Failed to destroy VirtualBox Instances, please check the logs for "
                "details."
            )
    
    def vagrant_machine_status(self):
        if self.count_resources() > 0:
            return "PROVISIONED"
        else:
            return "DESTROYED"

    def install_collection(self, collection_name, version=None):
        if version:
            collection_name += ":%s" % version
        try:
            output = exec_shell([
                self.bin("ansible-galaxy"),
                "collection",
                "install",
                "-f",
                collection_name
            ])
            result = output.decode("utf-8")
            logging.debug("Command output:")
            for l in result.split("\n"):
                logging.debug(l)
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def run_playbook(
        self, cloud, ssh_user, ssh_priv_key, inventory, playbook, extra_vars
    ):
        try:
            command = [
                    self.bin("ansible-playbook"),
                    playbook,
                    "--ssh-common-args='-o StrictHostKeyChecking=no'",
                    "-i", inventory,
                    "-u", ssh_user,
                    "--private-key", ssh_priv_key,
                    "-e", "'%s'" % extra_vars
                ]
            rc = exec_shell_live(command, cwd=self.dir)
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                "Failed to execute Ansible playbook, please check the logs for"
                " details."
            )

    def list_inventory(self, inventory):
        try:
            output = exec_shell([
                self.bin("ansible-inventory"),
                "--list",
                "-i", inventory
            ])
            result = json.loads(output.decode("utf-8"))
            logging.debug("Command output: %s", result)
            return result
        except ValueError:
            # JSON decoding error
            logging.error("Failed to decode JSON data")
            logging.error("Output: %s", output.decode("utf-8"))
            raise CliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def install(self, installation_path):
        pass
