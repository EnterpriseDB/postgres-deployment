import argcomplete
import argparse
import logging
import os
import sys

from . import __version__, command
from .commands import (
    aurora as aws_rds_aurora,
    aws,
    aws_pot,
    azure,
    azure_pot,
    azure_db,
    baremetal,
    rds as aws_rds,
    gcloud,
    gcloud_pot,
    gcloud_sql,
    vmware,
    virtualbox
)
from .errors import (
    AnsibleCliError,
    CliError,
    CloudCliError,
    ProjectError,
    SpecValidatorError,
    TerraformCliError,
)
from .project import Project


# Mapping between cloud vendor codes and their title and sub-command definition
CLI_CLOUD_VENDORS = {
    'aws': ('AWS Cloud', aws),
    'aws-pot': ('EDB POT on AWS Cloud', aws_pot),
    'aws-rds': ('AWS RDS Cloud', aws_rds),
    'aws-rds-aurora': ('AWS RDS Aurora Cloud', aws_rds_aurora),
    'azure': ('Azure Cloud', azure),
    'azure-pot': ('EDB POT on Azure Cloud', azure_pot),
    'azure-db': ('Azure Database Cloud', azure_db),
    'gcloud': ('Google Cloud', gcloud),
    'gcloud-pot': ('EDB POT on Google Cloud', gcloud_pot),
    'gcloud-sql': ('Google Cloud SQL', gcloud_sql),
    'baremetal': ('Baremetal servers and VMs', baremetal),
    'vmware': ('VMWare Workstation', vmware),
    'virtualbox': ('VirtualBox', virtualbox),
}


class CLIParser(argparse.ArgumentParser):
    def error(self, message):
        if message == "too few arguments":
            self.print_help()
        sys.stderr.write('error: %s\n' % message)
        sys.exit(2)


class EDBDeploymentCLI():
    def __init__(self, args=sys.argv[1:]):
        self.args = args
        self.commander = None

    def parse(self):
        """
        Parse and check command line arguments
        """
        parser = CLIParser(
            description='EDB deployment script for %s'
                        % ', '.join(CLI_CLOUD_VENDORS.keys())
        )
        parser.add_argument(
            '-v', '--version',
            dest='version',
            action='store_true',
            help="show version."
        )
        subparsers = parser.add_subparsers(
            title='Cloud provider', dest='cloud', metavar='<cloud>'
        )

        # Keep a track of the parsers to display help messages in case of error.
        parsers = dict()

        for code, (title, cmd) in CLI_CLOUD_VENDORS.items():
            parsers[code] = subparsers.add_parser(code, help=title)
            cmd.subcommands(
                parsers[code].add_subparsers(
                    title='%s sub-commands' % title,
                    dest='sub_command',
                    metavar='<sub-command>'
                )
            )

        # Autocompletion with argcomplete
        argcomplete.autocomplete(parser)

        # Parse the arguments and options
        env = parser.parse_args(self.args)

        # -v / --version
        # Show version and exit
        if env.version:
            print(__version__)
            sys.exit(0)

        # Check if the <cloud> argument is set
        if not getattr(env, 'cloud'):
            parser.print_help()
            sys.stderr.write('error: too few arguments\n')
            sys.exit(2)
        # Check if the <sub-command> argument is set
        if not getattr(env, 'sub_command'):
            parsers[env.cloud].print_help()
            sys.stderr.write('error: too few arguments\n')
            sys.exit(2)

        return env

    def configure_logging(self, env, commander):
        """
        Create logging directory and configure the log file name.
        Depending on if a project name is passed or not, the log file
        location is different. When a project name is passed, the file is
        stored inside project's directory, in the other case, it's
        located in the log/ dir.
        """
        if commander.project:
            commander.project.create_log_dir()
            log_filename = commander.project.log_file
        else:
            Project.create_root_log_dir()
            log_filename=os.path.join(
                Project.projects_root_path, "log",
                "%s_%s.log" % (env.cloud, env.sub_command)
            )
        # Logging module configuration
        logging.basicConfig(
            filename=log_filename,
            level=logging.DEBUG,
            format='%(asctime)s %(levelname)7s '+env.sub_command+': %(message)s',  # noqa
            datefmt='%Y-%m-%d %H:%M:%S',
        )

    def execute(self):
        """
        Execute the sub-command
        """
        # Parse the commande line and create a new instance of Commander in
        # charge of executing the sub-command.
        env = self.parse()
        self.commander = command.Commander(env)

        self.configure_logging(env, self.commander)

        logging.debug("env=%s", env)

        # Execute the sub-command
        self.commander.execute()

    def main(self):
        """
        Main method called by the main script
        """
        try:
            self.execute()
        except (
            command.CommanderError,
            CliError,
            CloudCliError,
            ProjectError,
            TerraformCliError,
            AnsibleCliError,
            SpecValidatorError
        ) as e:
            # Update states
            if isinstance(e, TerraformCliError):
                self.commander.project.update_state('terraform', 'FAIL')
            if isinstance(e, AnsibleCliError):
                self.commander.project.update_state('ansible', 'FAIL')

            sys.stderr.write("ERROR: %s\n" % str(e))
            sys.exit(2)
        except KeyboardInterrupt as e:
            sys.exit(1)
        except Exception as e:
            # Unhandled error
            sys.stderr.write("ERROR: %s\n" % str(e))
            logging.exception(str(e))
            sys.exit(2)
