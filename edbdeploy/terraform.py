import logging
import os
import re
from subprocess import CalledProcessError
import textwrap

from .installation import (
    execute_install_script,
    build_tmp_install_script,
    uname,
)
from .system import exec_shell_live, exec_shell
from .errors import TerraformCliError
from . import check_version, to_str


class TerraformCli:

    def __init__(self, dir, plugin_cache_dir, bin_path=None):
        self.dir = dir
        self.plugin_cache_dir = plugin_cache_dir
        self.environ = os.environ.copy()
        self.environ['TF_PLUGIN_CACHE_DIR'] = self.plugin_cache_dir
        # Terraform supported version interval
        self.min_version = (1, 0, 0)
        self.max_version = (1, 0, 1)
        # Path to look up for executable
        self.bin_path = None
        # Force Terraform binary path if bin_path exists and contains
        # terraform file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'terraform')):
                self.bin_path = bin_path
                # Add terraform bin path to the PATH env. variable. This is
                # needed to cover the case when binaries are localted in
                # ~/.edb-cloud-tools/bin and terraform needs to execute the az
                # command.
                self.environ['PATH'] = "%s:%s" % (
                    self.environ['PATH'], self.bin_path
                )

    def check_version(self):
        """
        Verify terraform version, based on the interval formed by min_version
        and max_version.
        Terraform version is fetched using the command: terraform --version
        """
        # note: we do not raise any TerraformCliError from this function
        # because TerraformCliError are used to trigger stuffs when they are
        # catched. In this case, we do not want trigger anything if something
        # fails.
        try:
            output = exec_shell(
                [self.bin("terraform"), "--version"],
                environ=self.environ
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "Terraform executable seems to be missing. Please install it "
                "or check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^Terraform v([0-9]+)\.([0-9]+)\.([0-9]+)$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise Exception("Unable to parse Terraform version")

        logging.info("Terraform version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.min_version, self.max_version):
            raise Exception(
                ("Terraform version %s not supported, must be between %s and"
                 "%s") % (to_str(version), to_str(self.min_version),
                          to_str(self.max_version)))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def init(self):
        try:
            rc = exec_shell_live(
                [self.bin("terraform"), "init", "-no-color"],
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
                    self.bin("terraform"),
                    "apply",
                    "-auto-approve",
                    "-var-file",
                    vars_file,
                    "-no-color"
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
                    self.bin("terraform"),
                    "destroy",
                    "-auto-approve",
                    "-var-file",
                    vars_file,
                    "-no-color"
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
                [self.bin("terraform"), "state", "list"],
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

    def install(self, installation_path):
        """
        Terraform installation
        """
        # Installation bash script content
        installation_script = textwrap.dedent("""
            #!/bin/bash
            set -eu

            mkdir -p {path}/terraform/{version}/bin
            wget -q https://releases.hashicorp.com/terraform/{version}/terraform_{version}_{os_flavor}_amd64.zip -O /tmp/terraform.zip
            unzip /tmp/terraform.zip -d {path}/terraform/{version}/bin
            rm -f /tmp/terraform.zip
            rm -f {path}/bin/terraform
            ln -sf {path}/terraform/{version}/bin/terraform {path}/bin/.
        """)

        # Generate the installation script as an executable tempfile
        script_name = build_tmp_install_script(
            installation_script.format(
                path=installation_path,
                version='.'.join(str(i) for i in self.max_version),
                os_flavor=uname().lower()
            )
        )

        # Execute the installation script
        execute_install_script(script_name)
