import logging
import os
import stat
import re
from subprocess import CalledProcessError
import textwrap

from .installation import (
    execute_install_script,
    build_tmp_install_script,
    uname,
)
from .system import exec_shell_live, exec_shell
from .password import save_password
from .errors import TPAexecCliError
from . import check_version, to_str


class TPAexecCli:

    def __init__(self, dir, bin_path=None, tpa_subscription_token=None):
        self.dir = dir
        self.environ = os.environ.copy()
        self.environ['TPA_2Q_SUBSCRIPTION_TOKEN'] = tpa_subscription_token
        self.environ['EDB_REPO_CREDENTIALS_FILE'] = os.path.join(self.dir, 'edb-credentials')
        self.environ['ANSIBLE_PIPELINING'] = 'true'
        self.environ['ANSIBLE_SSH_PIPELINING'] = 'true'
        # Terraform supported version interval
        self.min_version = (22, 14)
        self.max_version = (22, 14)
        # Path to look up for executable
        self.bin_path = None
        # Force tpaexec binary path if bin_path exists and contains
        # tpaexec file.
        if bin_path is not None and os.path.exists(bin_path):
            if os.path.exists(os.path.join(bin_path, 'tpaexec')):
                self.bin_path = bin_path
                # Add tpaexec bin path to the PATH env. variable. This is
                # needed to cover the case when binaries are localted in
                # ~/.edb-cloud-tools/bin and tpaexec needs to execute the az
                # command.
                self.environ['PATH'] = "%s:%s" % (
                    self.environ['PATH'], self.bin_path
                )
        # Ensure permission on edb-credentials 0600
        os.chmod(os.path.join(self.dir,'edb-credentials'), stat.S_IREAD | stat.S_IWRITE)

    def check_version(self):
        """
        Verify tpaexec version, based on the interval formed by min_version
        and max_version.
        Terraform version is fetched using the command: tpaexec --version
        """
        # note: we do not raise any TPAexecCliError from this function
        # because TPAexecCliError are used to trigger stuffs when they are
        # catched. In this case, we do not want trigger anything if something
        # fails.
        try:
            output = exec_shell(
                [self.bin("tpaexec"), "--version"],
                environ=self.environ
            )
        except CalledProcessError as e:
            logging.error("Failed to execute the command: %s", e.cmd)
            logging.error("Return code is: %s", e.returncode)
            logging.error("Output: %s", e.output)
            raise Exception(
                "TPAexec executable seems to be missing. Please install it "
                "or check your PATH variable"
            )
        version = None
        # Parse command output and extract the version number
        pattern = re.compile(r"^# TPAexec ([0-9]+)\.([0-9]+)$")
        for line in output.decode("utf-8").split("\n"):
            m = pattern.search(line)
            if m:
                version = (int(m.group(1)), int(m.group(2)))
                break

        if version is None:
            raise Exception("Unable to parse Terraform version")

        logging.info("TPAexec version: %s", '.'.join(map(str, version)))

        if not check_version(version, self.min_version, self.max_version):
            raise Exception(
                ("TPAexec version %s not supported, must be between %s and"
                 " %s") % (to_str(version), to_str(self.min_version),
                          to_str(self.max_version)))

    def bin(self, binary):
        """
        Return binary's path
        """
        if self.bin_path is not None:
            return os.path.join(self.bin_path, binary)
        else:
            return binary

    def relink(self):
        try:
            rc = exec_shell_live(
                [
                     self.bin("tpaexec"),
                     "relink",
                     "."
                ],
                environ=self.environ,
                cwd=self.dir
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TPAexecCliError(
                "Failed to execute tpaexec relink on project, please check the logs"
                " for details."
            )

    def provision(self):
        try:
            rc = exec_shell_live(
                [
                     self.bin("tpaexec"),
                     "provision",
                     "."
                ],
                environ=self.environ,
                cwd=self.dir
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TPAexecCliError(
                "Failed to execute tpaexec provision on project, please check the logs"
                " for details."
            )

    def deploy(self):
        try:
            rc = exec_shell_live(
                [
                    self.bin("tpaexec"),
                    "deploy",
                    "."
                ],
                environ=self.environ,
                cwd=self.dir
            )
            if rc != 0:
                raise Exception("Return code not 0")
        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TPAexecCliError(
                "Failed to deploy with tpaexec, please check the logs for details."
            )

    def tpa_password(self, username):
        try:
            output = exec_shell(
                [
                    self.bin("tpaexec"),
                    "show-password",
                    ".",
                    username,
                    " 2>/dev/null"
                ],
                environ=self.environ,
                cwd=self.dir
            )

            password = output.decode("utf-8")
            save_password(self.dir, username, password)

        except Exception as e:
            logging.error("Failed to execute the command")
            logging.error(e)
            raise TPAexecCliError(
                "Failed to tpaexec show-password, please check the logs for details."
            )
