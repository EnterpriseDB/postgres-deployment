import argparse

from ..options import *
from .default import default_subcommand_parsers

# AWS RDS Aurora for sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the aws-rds-aurora
    # command
    available_subcommands = [
        'configure', 'deploy', 'destroy', 'display', 'list', 'logs',
        'passwords', 'provision', 'setup', 'show', 'specs', 'remove'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )

    # aws-rds-aurora configure sub-command options
    subcommand_parsers['configure'].add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOptionRDS.choices,
        default=ReferenceArchitectureOptionRDS.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOptionRDS.help
    )
    subcommand_parsers['configure'].add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    ).completer = edb_credentials_completer
    subcommand_parsers['configure'].add_argument(
        '-o', '--os',
        dest='operating_system',
        choices=OSOption.choices,
        default=OSOption.default,
        metavar='<operating-system>',
        help=OSOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOptionRDS.choices,
        default=PgTypeOptionRDS.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOptionRDS.help
    )
    subcommand_parsers['configure'].add_argument(
        '-v', '--pg-version',
        dest='postgres_version',
        choices=PgVersionOption.choices,
        default=PgVersionOption.default,
        metavar='<postgres-version>',
        help=PgVersionOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-k', '--ssh-pub-key',
        dest='ssh_pub_key',
        type=argparse.FileType('r'),
        default=SSHPubKeyOption.default(),
        metavar='<ssh-public-key-file>',
        help=SSHPubKeyOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-K', '--ssh-private-key',
        dest='ssh_priv_key',
        type=argparse.FileType('r'),
        default=SSHPrivKeyOption.default(),
        metavar='<ssh-private-key-file>',
        help=SSHPrivKeyOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-r', '--aws-rds-region',
        dest='aws_region',
        choices=AWSRegionOption.choices,
        default=AWSRegionOption.default,
        metavar='<cloud-region>',
        help=AWSRegionOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-i', '--aws-rds-ami-id',
        dest='aws_ami_id',
        type=str,
        default=AWSIAMIDOption.default,
        metavar='<aws-rds-ami-id>',
        help=AWSIAMIDOption.help
    ).completer = aws_ami_id_completer
    subcommand_parsers['configure'].add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<aws-rds-spec-file>',
        help="AWS instances specification file, in JSON."
    )
    subcommand_parsers['configure'].add_argument(
        '-T', '--t-shirt',
        dest='shirt',
        choices=ShirtSizeOption.choices,
        default=ShirtSizeOption.default,
        metavar='<shirt-size>',
        help=ShirtSizeOption.help
    )
    # aws-rds-aurora logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # aws-rds-aurora deploy sub-command options
    subcommand_parsers['deploy'].add_argument(
        '-n', '--no-install-collection',
        dest='no_install_collection',
        action='store_true',
        help="Do not install the Ansible collection."
    )
