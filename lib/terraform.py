import logging
import os

from .system import exec_shell_live


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
