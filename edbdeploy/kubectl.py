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
from .errors import KubectlCliError
from . import check_version, to_str


class KubectlCli:

    def __init__(self, dir, plugin_cache_dir, bin_path=None):
        self.dir = dir
        self.plugin_cache_dir = plugin_cache_dir
        self.environ = os.environ.copy()
        #self.environ['TF_PLUGIN_CACHE_DIR'] = self.plugin_cache_dir
        # Kubectl supported version interval
        #self.min_version = (1, 0, 0)
#        self.max_version = (1, 0, 1)
        #self.max_version = (1, 2, 6)
        # Path to look up for executable
        self.bin_path = None
        # Force Kubectl binary path if bin_path exists and contains
        # Kubectl file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'kubectl')):
                self.bin_path = bin_path
                # Add kubectl bin path to the PATH env. variable. This is
                # needed to cover the case when binaries are localted in
                # ~/.edb-cloud-tools/bin and kubectl needs to execute the az
                # command.
                self.environ['PATH'] = "%s:%s" % (
                    self.environ['PATH'], self.bin_path
                )

    def check_version(self):
        """
        Verify kubectl version, based on the interval formed by min_version
        and max_version.
        Kubectl version is fetched using the command: kubectl --version
        """
        # note: we do not raise any KubectlCliError from this function
        # because KubectlCliError are used to trigger stuffs when they are
        # catched. In this case, we do not want trigger anything if something
        # fails.
        try:
            output = exec_shell(
                [self.bin("kubectl"), "version"],
                environ=self.environ
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "Kubectl executable seems to be missing. Please install it "
                "or check your PATH variable"
            )

        version = None

        if version is None:
            raise Exception("Unable to parse Kubectl version")

        logging.info("Kubectl version: %s", '.'.join(map(str, version)))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def install(self, installation_path):
        """
        Kubectl installation
        """
        # Installation bash script content
        installation_script = textwrap.dedent("""
            #!/bin/bash
            set -eu

            mkdir -p {path}/kubectl/{version}/bin
            wget -q https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
            chmod +x ./kubectl
            mv ./kubectl /usr/local/bin/kubectl
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