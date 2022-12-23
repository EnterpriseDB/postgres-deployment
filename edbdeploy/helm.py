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
from .errors import HelmCliError
from . import check_version, to_str


class HelmCli:

    def __init__(self, dir, plugin_cache_dir, bin_path=None):
        self.dir = dir
        self.plugin_cache_dir = plugin_cache_dir
        self.environ = os.environ.copy()
        #self.environ['TF_PLUGIN_CACHE_DIR'] = self.plugin_cache_dir
        # Helm supported version interval
        self.min_version = (3, 10, 3)
        self.max_version = (3, 10, 3)
        # Path to look up for executable
        self.bin_path = None
        # Force Helm binary path if bin_path exists and contains
        # terraform file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'helm')):
                self.bin_path = bin_path
                # Add kubectl bin path to the PATH env. variable. This is
                # needed to cover the case when binaries are localted in
                # ~/.edb-cloud-tools/bin and terraform needs to execute the az
                # command.
                self.environ['PATH'] = "%s:%s" % (
                    self.environ['PATH'], self.bin_path
                )

    def check_version(self):
        """
        Verify Helm version, based on the interval formed by min_version
        and max_version.
        Helm version is fetched using the command: helm version --template='{{.Version}}'
        """
        # note: we do not raise any HelmCliError from this function
        # because HelmCliError are used to trigger stuffs when they are
        # catched. In this case, we do not want trigger anything if something
        # fails.
        try:
            output = exec_shell([
                self.bin("helm", "version", ),
                "--template='{{.Version}}'"
            ])            
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "Helm executable seems to be missing. Please install it "
                "or check your PATH variable"
            )

        version = None
        # Parse command output and extract the version number
        # Output can be:
        # - helm v3.10.3
        pattern = re.compile(r"^helmD*(\d+)\.(\d+)\.(\d+)\D*$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)), int(m.group(3)))
                break

        if version is None:
            raise Exception("Unable to parse Helm version")

        logging.info("Helm version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.min_version, self.max_version):
            raise HelmCliError(
                "Helm version %s not supported, must be between %s and %s"
                % (to_str(version), to_str(self.min_version),
                   to_str(self.max_version)))

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
        Helm and PreReqs Installation
        """
        # Installation bash script content
        installation_script = textwrap.dedent("""
            #!/bin/bash
            set -eu

            mkdir -p {path}/kubectl/{version}/bin
            curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
            chmod +x ./get_helm.sh
            ./get_helm.sh
            rm ./get_helm.sh            

            # Install gcloud gke plugin
            gcloud components install gke-gcloud-auth-plugin
            gcloud components install kubectl
            # Install dependency packages            
            pip install openshift pyyaml kubernetes 
            pip install pyhelm
            # Install Ansible Galaxy Collections
            ansible-galaxy collection install kubernetes.core --force
            ansible-galaxy collection install community.kubernetes --force
            ansible-galaxy collection install edb_devops.edb_postgres --force
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