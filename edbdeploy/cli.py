import argcomplete
import argparse
import sys

from . import __version__
from .commands import (
    aurora as aws_rds_aurora,
    aws,
    azure,
    baremetal,
    rds as aws_rds,
    gcloud,
)


class CLIParser(argparse.ArgumentParser):
    def error(self, message):
        if message == "too few arguments":
            self.print_help()
        sys.stderr.write('error: %s\n' % message)
        sys.exit(2)


def parse():
    parser = CLIParser(
        description='EDB deployment script for aws, aws-rds, azure and gcloud'
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

    # Cloud commands parsers
    aws_parser = subparsers.add_parser('aws', help='AWS Cloud')
    aws_rds_parser = subparsers.add_parser('aws-rds', help='AWS RDS Cloud')
    aws_rds_aurora_parser = subparsers.add_parser(
        'aws-rds-aurora', help='AWS RDS Aurora Cloud'
    )
    azure_parser = subparsers.add_parser('azure', help='Azure Cloud')
    gcloud_parser = subparsers.add_parser('gcloud', help='Google Cloud')
    baremetal_parser = subparsers.add_parser(
        'baremetal', help='Baremetal servers and VMs'
    )

    # Sub-commands parsers
    aws_subparser = aws_parser.add_subparsers(
        title='AWS sub-commands', dest='sub_command', metavar='<sub-command>'
    )
    aws_rds_subparser = aws_rds_parser.add_subparsers(
        title='AWS RDS sub-commands', dest='sub_command', metavar='<sub-command>'
    )
    aws_rds_aurora_subparser = aws_rds_aurora_parser.add_subparsers(
        title='AWS RDS Aurora sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    azure_subparser = azure_parser.add_subparsers(
        title='Azure sub-commands', dest='sub_command', metavar='<sub-command>'
    )
    gcloud_subparser = gcloud_parser.add_subparsers(
        title='GCloud sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    baremetal_subparser = baremetal_parser.add_subparsers(
        title='Baremetal sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )

    # Attach sub-commands options to the sub-parsers
    aws.subcommands(aws_subparser)
    aws_rds.subcommands(aws_rds_subparser)
    aws_rds_aurora.subcommands(aws_rds_aurora_subparser)
    azure.subcommands(azure_subparser)
    gcloud.subcommands(gcloud_subparser)
    baremetal.subcommands(baremetal_subparser)

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
        if env.cloud == 'aws':
            aws_parser.print_help()
        elif env.cloud == 'aws-rds':
            aws_rds_parser.print_help()
        elif env.cloud == 'aws-rds-aurora':
            aws_rds_aurora_parser.print_help()
        elif env.cloud == 'azure':
            azure_parser.print_help()
        elif env.cloud == 'gcloud':
            gcloud_parser.print_help()
        elif env.cloud == 'baremetal':
            baremetal_parser.print_help()
        sys.stderr.write('error: too few arguments\n')
        sys.exit(2)

    return env
