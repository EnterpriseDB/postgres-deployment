import json
import logging
import os
import re
from subprocess import CalledProcessError
import textwrap

from .errors import AnsibleCliError, CliError
from .installation import build_tmp_install_script, execute_install_script
from .system import exec_shell_live, exec_shell


class AnsibleCli:

    def __init__(self, dir, bin_path=None):
        self.dir = dir
        # Ansible supported versions interval
        self.min_version = (0, 0, 0)
        self.max_version = (2, 10, 7)
        # Path to look up for executable
        self.bin_path = None
        # Force Ansible binary path if bin_path exists and contains
        # ansible file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'ansible')):
                self.bin_path = bin_path

    def check_version(self):
        """
        Verify ansible version, based on the interval formed by min_version and
        max_version.
        Ansible version is fetched using the command: ansible --version
        """
        # note: we do not raise any AnsibleCliError from this function because
        # AnsibleCliError are used to trigger stuffs when they are catched. In
        # this case, we do not want trigger anything if something fails.
        try:
            output = exec_shell([
                self.bin("ansible"),
                "--version"
            ])
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise CliError(
                "Ansible executable seems to be missing. Please install it or "
                "check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^ansible ([0-9]+)\.([0-9]+)\.([0-9]+)$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise CliError("Unable to parse Ansible version")

        logging.info("Ansible version: %s", '.'.join(map(str, version)))

        # Verify if the version fetched is supported
        for i in range(0, 3):
            min = self.min_version[i]
            max = self.max_version[i]

            if version[i] < max:
                # If current digit is below the maximum value, no need to
                # check others digits, we are good
                break

            if version[i] not in list(range(min, max + 1)):
                raise CliError(
                    ("Ansible version %s not supported, must be between %s and"
                     " %s") % (
                        '.'.join(map(str, version)),
                        '.'.join(map(str, self.min_version)),
                        '.'.join(map(str, self.max_version)),
                    )
                )

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

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
            raise AnsibleCliError(
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
            if cloud in ['aws-rds', 'aws-rds-aurora']:
                command.append('--limit')
                command.append('!primary')
            rc = exec_shell_live(command, cwd=self.dir)
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise AnsibleCliError(
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
            raise AnsibleCliError(
                "Failed to decode JSON data, please check the logs for details"
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise AnsibleCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )

    def install(self, installation_path):
        """
        Ansible installation
        """
        # Installation bash script content
        installation_script = textwrap.dedent("""
            #!/bin/bash
            set -eu

            mkdir -p {path}/ansible/{version}
            python3 -m venv {path}/ansible/{version}
            sed -i.bak 's/$1/${{1:-}}/' {path}/ansible/{version}/bin/activate
            source {path}/ansible/{version}/bin/activate
            python3 -m pip install "cryptography==3.3.2"
            python3 -m pip install "ansible-base=={version}"
            python3 -m pip install "ansible=={version}"
            deactivate
            rm -f {path}/bin/ansible
            ln -sf {path}/ansible/{version}/bin/ansible {path}/bin/.
            rm -f {path}/bin/ansible-galaxy
            ln -sf {path}/ansible/{version}/bin/ansible-galaxy {path}/bin/.
            rm -f {path}/bin/ansible-playbook
            ln -sf {path}/ansible/{version}/bin/ansible-playbook {path}/bin/.
            rm -f {path}/bin/ansible-inventory
            ln -sf {path}/ansible/{version}/bin/ansible-inventory {path}/bin/.
        """)

        # Generate the installation script as an executable tempfile
        script_name = build_tmp_install_script(
            installation_script.format(
                path=installation_path,
                version='.'.join(str(i) for i in self.max_version)
            )
        )

        # Execute the installation script
        execute_install_script(script_name)
