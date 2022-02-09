import logging
import os
import stat
from subprocess import CalledProcessError
from tempfile import mkstemp

from .errors import CliError
from .system import exec_shell


def build_tmp_install_script(content):
    """
    Generate the installation script as an executable tempfile and returns its
    path.
    """
    script_handle, script_name = mkstemp(suffix='.sh')
    try:
        with open(script_handle, 'w') as f:
            f.write(content)
        st = os.stat(script_name)
        os.chmod(script_name, st.st_mode | stat.S_IEXEC)
        return script_name
    except Exception as e:
        logging.error("Unable to generate the installation script")
        logging.exception(str(e))
        raise CliError("Unable to generate the installation script")


def execute_install_script(script_name):
    """
    Execute an installation script
    """
    try:
        output = exec_shell(['/bin/bash', script_name])
        result = output.decode("utf-8")
        os.unlink(script_name)
        logging.debug("Command output: %s", result)
    except CalledProcessError as e:
        logging.error("Failed to execute the command: %s", e.cmd)
        logging.error("Return code is: %s", e.returncode)
        logging.error("Output: %s", e.output)
        raise CliError(
            "Failed to execute the following command, please check the "
            "logs for details: %s" % e.cmd
        )


def uname():
    """
    Execute the uname Unix command
    """
    try:
        output = exec_shell(['uname'])
        result = output.decode("utf-8")
        logging.debug("Command output: %s", result)
        return str(result).strip()
    except CalledProcessError as e:
        logging.error("Failed to execute the command: %s", e.cmd)
        logging.error("Return code is: %s", e.returncode)
        logging.error("Output: %s", e.output)
        raise CliError(
            "Failed to execute the following command, please check the "
            "logs for details: %s" % e.cmd
        )
