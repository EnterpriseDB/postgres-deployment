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
)


class CLIParser(argparse.ArgumentParser):
    def error(self, message):
        if message == "too few arguments":
            self.print_help()
        sys.stderr.write('error: %s\n' % message)
        sys.exit(2)


def parse():
    parser = CLIParser(
        description='EDB deployment script for aws, aws-rds, azure, azure-db, gcloud, and gcloud-sql'
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
    aws_pot_parser = subparsers.add_parser(
        'aws-pot', help='EDB POT on AWS Cloud'
    )
    aws_rds_parser = subparsers.add_parser('aws-rds', help='AWS RDS Cloud')
    aws_rds_aurora_parser = subparsers.add_parser(
        'aws-rds-aurora', help='AWS RDS Aurora Cloud'
    )
    azure_parser = subparsers.add_parser('azure', help='Azure Cloud')
    azure_pot_parser = subparsers.add_parser(
        'azure-pot', help='EDB POT on Azure Cloud'
    )
    azure_db_parser = subparsers.add_parser('azure-db',
                                            help='Azure Database Cloud')
    gcloud_parser = subparsers.add_parser('gcloud', help='Google Cloud')
    gcloud_pot_parser = subparsers.add_parser(
        'gcloud-pot', help='EDB POT on Google Cloud'
    )
    gcloud_sql_parser = subparsers.add_parser('gcloud-sql',
                                              help='Google Cloud SQL')
    baremetal_parser = subparsers.add_parser(
        'baremetal', help='Baremetal servers and VMs'
    )
    vmware_parser = subparsers.add_parser('vmware', help='VMWare Workstation')

    # Sub-commands parsers
    aws_subparser = aws_parser.add_subparsers(
        title='AWS sub-commands', dest='sub_command', metavar='<sub-command>'
    )
    aws_pot_subparser = aws_pot_parser.add_subparsers(
        title='EDB POT on AWS sub-commands', dest='sub_command',
        metavar='<sub-command>'
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
    azure_pot_subparser = azure_pot_parser.add_subparsers(
        title='EDB POT on Azure sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    azure_db_subparser = azure_db_parser.add_subparsers(
        title='Azure Database sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    gcloud_subparser = gcloud_parser.add_subparsers(
        title='GCloud sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    gcloud_pot_subparser = gcloud_pot_parser.add_subparsers(
        title='EDB POT on GCloud sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    gcloud_sql_subparser = gcloud_sql_parser.add_subparsers(
        title='Google Cloud SQL sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    baremetal_subparser = baremetal_parser.add_subparsers(
        title='Baremetal sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )
    vmware_subparser = vmware_parser.add_subparsers(
        title='VMWare sub-commands', dest='sub_command',
        metavar='<sub-command>'
    )

    # Attach sub-commands options to the sub-parsers
    aws.subcommands(aws_subparser)
    aws_pot.subcommands(aws_pot_subparser)
    aws_rds.subcommands(aws_rds_subparser)
    aws_rds_aurora.subcommands(aws_rds_aurora_subparser)
    azure.subcommands(azure_subparser)
    azure_pot.subcommands(azure_pot_subparser)
    azure_db.subcommands(azure_db_subparser)
    gcloud.subcommands(gcloud_subparser)
    gcloud_pot.subcommands(gcloud_pot_subparser)
    gcloud_sql.subcommands(gcloud_sql_subparser)
    baremetal.subcommands(baremetal_subparser)
    vmware.subcommands(vmware_subparser)

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
        elif env.cloud == 'aws-pot':
            aws_pot_parser.print_help()
        elif env.cloud == 'aws-rds':
            aws_rds_parser.print_help()
        elif env.cloud == 'aws-rds-aurora':
            aws_rds_aurora_parser.print_help()
        elif env.cloud == 'azure':
            azure_parser.print_help()
        elif env.cloud == 'azure-pot':
            azure_pot_parser.print_help()
        elif env.cloud == 'azure-db':
            azure_db_parser.print_help()
        elif env.cloud == 'gcloud':
            gcloud_parser.print_help()
        elif env.cloud == 'gcloud-pot':
            gcloud_pot_parser.print_help()
        elif env.cloud == 'gcloud-sql':
            gcloud_sql_parser.print_help()
        elif env.cloud == 'baremetal':
            baremetal_parser.print_help()
        elif env.cloud == 'vmware':
            vmware_parser.print_help()
        sys.stderr.write('error: too few arguments\n')
        sys.exit(2)

    return env
