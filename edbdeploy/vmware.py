import json
import logging
import os
import re
from subprocess import CalledProcessError
import textwrap

from .errors import VMWareCliError, CliError
from .installation import build_tmp_install_script, execute_install_script
from .system import exec_shell_live, exec_shell
from . import check_version, to_str


class VMWareCli:

    def __init__(self, dir, name, cloud, mem_size, cpu_count, mech_project_path, bin_path=None):
        self.dir = dir
        self.environ = os.environ
        self.name = name
        self.cloud = cloud
        self.mem_size = mem_size
        self.cpu_count = cpu_count
        self.mech_project_path = mech_project_path

        # Python supported versions interval
        self.python_min_version = (3, 8, 0)
        self.python_max_version = (9, 9, 9)
        # Vagrant supported versions interval
        self.vagrant_min_version = (2, 0, 0)
        self.vagrant_max_version = (9, 9, 9)
        # Mech supported versions interval
        self.mech_min_version = (0, 3, 0)
        self.mech_max_version = (9, 9, 9)
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

    def mech_check_version(self):
        """
        Verify mech version, based on the interval formed by mech_min_version and
        mech_max_version.
        Mech version is fetched using the command: mech --version
        """
        # note: we do not raise any AnsibleCliError from this function because
        # AnsibleCliError are used to trigger stuffs when they are catched. In
        # this case, we do not want trigger anything if something fails.
        try:
            output = exec_shell([
                self.bin("mech"),
                "--version"
            ])
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CliError(
                "Mech executable seems to be missing. Please install it or "
                "check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^mech v([0-9]+)\.([0-9]+)\.([0-9]+)$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise CliError("Unable to parse Mech version")

        logging.info("Mech version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.mech_min_version,
                             self.mech_max_version):
            raise CliError(
                "Mech version %s not supported, must be between %s and %s"
                % (to_str(version), to_str(self.mech_min_version),
                   to_str(self.mech_max_version)))

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
                [
                    self.bin("mech"),
                    "up",
                    "--memsize %s" % self.mem_size,
                    "--numvcpus %s" % self.cpu_count
                ],
                environ=self.environ,
                cwd=self.mech_project_path
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                "Failed to provision VMWare Instances, please check the logs for details."
            )

    def destroy(self):
        try:
            rc = exec_shell_live(
                [
                    self.bin("mech"),
                    "down",
                    "--force",
                ],
                environ=self.environ,
                cwd=self.mech_project_path
            )
            
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                "Failed to destroy VMWare Instances, please check the logs for details."
            )

    def count_resources(self):
        try:     
            #Use mech list see all running instances within, grep gets all instances with started as state which means its on, wc returns a count of the listed files with vmx
            output = exec_shell(
                [
                    self.bin("mech"),
                    "list",
                    "|",
                    self.bin("grep"),
                    "started",
                    "|",
                    self.bin("wc"),
                    "-l" 
                ],
                environ=self.environ,
                cwd=self.mech_project_path
            )
            result = output.decode("utf-8").strip()
            return int(result)
            
            
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise CliError(
                "Failed to destroy VMWare Instances, please check the logs for "
                "details."
            )
    
    def mech_machine_status(self):
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
