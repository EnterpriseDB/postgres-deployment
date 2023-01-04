import argparse

from ..options import *
from .default import default_subcommand_parsers

# GCloud GKE PG sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the aws command
    available_subcommands = [
        'configure', 'deploy', 'destroy', 'list', 'logs',
        'provision', 'setup', 'remove'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )
    # gcp configure sub-command options
    subcommand_parsers['configure'].add_argument(
        '-y', '--cnp-type',
        required=True,
        dest='cnpType',
        choices=GCloudCNPOption.choices,
        default=GCloudCNPOption.default,
        metavar='<cnpType>',
        help=GCloudCNPOption.help
    )    
    subcommand_parsers['configure'].add_argument(
        '-r', '--gcloud-region',
        required=True,
        dest='gcpRegion',
        choices=GCloudRegionOption.choices,
        default=GCloudRegionOption.default,
        metavar='<gcpRegion>',
        help=GCloudRegionOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-c', '--gcloud-credentials',
        required=True,        
        dest='gcp_credentials_file',
        type=argparse.FileType('r'),
        default=GCloudCredentialsOption.default(),
        metavar='<gcloud-credentials-json-file>',
        help=GCloudCredentialsOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-p', '--gcloud-project-id',
        dest='project_id',
        required=True,
        type=str,
        metavar='<project-id>',
        help="GCloud project ID"
    ).completer = gcloud_project_id_completer
    subcommand_parsers['configure'].add_argument(
        '-f', '--force',
        dest='force_configure',
        action='store_true',
        help="Force project configuration."
    )
    # gcp logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # gcp deploy sub-command options
    subcommand_parsers['deploy'].add_argument(
        '--disable-pipelining',
        dest='disable_pipelining',
        action='store_true',
        help="Disable Ansible pipelining."
    )
