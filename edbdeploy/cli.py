import argcomplete
import argparse
import sys

from . import __version__
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


def parse():
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
    env = parser.parse_args()

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
