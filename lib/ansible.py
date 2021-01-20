import json
import logging
from subprocess import CalledProcessError

from .system import exec_shell_live, exec_shell


class AnsibleCliError(Exception):
    pass


class AnsibleCli:

    def __init__(self, dir):
        self.dir = dir

    def install_collection(self, collection_name, version=None):
        if version:
            collection_name += ":%s" % version
        try:
            output = exec_shell([
                "ansible-galaxy",
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
        self, ssh_user, ssh_priv_key, inventory, playbook, extra_vars
    ):
        try:
            rc = exec_shell_live(
                [
                    "ansible-playbook",
                    playbook,
                    "--ssh-common-args='-o StrictHostKeyChecking=no'",
                    "-i", inventory,
                    "-u", ssh_user,
                    "--private-key", ssh_priv_key,
                    "-e", "'%s'" % extra_vars
                ],
                cwd=self.dir
            )
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
                "ansible-inventory",
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
