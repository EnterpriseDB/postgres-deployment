import logging
import os
from subprocess import CalledProcessError

from .system import exec_shell_live, exec_shell


class TerraformCliError(Exception):
    pass


class TerraformCli:

    def __init__(self, dir, plugin_cache_dir):
        self.dir = dir
        self.plugin_cache_dir = plugin_cache_dir
        self.environ = os.environ
        self.environ['TF_PLUGIN_CACHE_DIR'] = self.plugin_cache_dir

    def init(self):
        try:
            rc = exec_shell_live(
                ["terraform", "init", "-no-color", self.dir],
                environ=self.environ,
                cwd=self.dir
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TerraformCliError(
                "Failed to initialize Terraform project, please check the logs"
                " for details."
            )

    def apply(self, vars_file):
        try:
            rc = exec_shell_live(
                [
                    "terraform",
                    "apply",
                    "-auto-approve",
                    "-var-file",
                    vars_file,
                    "-no-color",
                    self.dir
                ],
                environ=self.environ,
                cwd=self.dir
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TerraformCliError(
                "Failed to apply Terraform, please check the logs for details."
            )

    def destroy(self, vars_file):
        try:
            rc = exec_shell_live(
                [
                    "terraform",
                    "destroy",
                    "-auto-approve",
                    "-var-file",
                    vars_file,
                    "-no-color",
                    self.dir
                ],
                environ=self.environ,
                cwd=self.dir
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TerraformCliError(
                "Failed to destroy Terraform, please check the logs for "
                "details."
            )

    def exec_add_host_sh(self):
        try:
            rc = exec_shell_live(
                ["./add_host.sh"], environ=self.environ, cwd=self.dir
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TerraformCliError(
                ("Failed to execute script %s, please check the logs for "
                 "details.") % os.path.join(self.dir, "add_host.sh")
            )

    def count_resources(self):
        try:
            # Check if the terraform state file exists
            if not os.path.exists(os.path.join(self.dir, 'terraform.tfstate')):
                return 0

            output = exec_shell(
                ["terraform", "state", "list"],
                environ=self.environ,
                cwd=self.dir
            )

            result = output.decode("utf-8").split('\n')
            logging.debug("Command output: %s", result)
            return len(result) - 1
        except CalledProcessError as e:
            # Case when the terraform.tfstate file exists but not yet fully
            # usable by terraform. In this case, we just return 0
            if (e.returncode == 1 and
                    "No state file was found!" in e.output.decode("utf-8")):
                return 0

            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise TerraformCliError(
                "Failed to execute the following command, please check the "
                "logs for details: %s" % e.cmd
            )
