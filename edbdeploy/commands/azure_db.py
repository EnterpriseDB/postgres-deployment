import argparse

from ..options import *
from .default import default_subcommand_parsers

# Azure Database sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the azure-db command
    available_subcommands = [
        'configure', 'deploy', 'destroy', 'display', 'list', 'logs',
        'passwords', 'provision', 'show', 'specs', 'remove'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )

    # azure-db configure sub-command options
    subcommand_parsers['configure'].add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOptionDBaaS.choices,
        default=ReferenceArchitectureOptionDBaaS.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOptionDBaaS.help
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
        choices=PgTypeOptionAzureDB.choices,
        default=PgTypeOptionAzureDB.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOptionAzureDB.help
    )
    subcommand_parsers['configure'].add_argument(
        '-v', '--pg-version',
        dest='postgres_version',
        choices=PgVersionOptionAzureDB.choices,
        default=PgVersionOptionAzureDB.default,
        metavar='<postgres-version>',
        help=PgVersionOptionAzureDB.help
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
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<azure-db-spec-file>',
        help="Azure instances specification file, in JSON."
    )
    subcommand_parsers['configure'].add_argument(
        '-r', '--azure-region',
        dest='azure_region',
        choices=AzureRegionOption.choices,
        default=AzureRegionOption.default,
        metavar='<cloud-region>',
        help=AzureRegionOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-T', '--t-shirt',
        dest='shirt',
        choices=ShirtSizeOption.choices,
        default=ShirtSizeOption.default,
        metavar='<shirt-size>',
        help=ShirtSizeOption.help
    )
    # azure-db logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # azure-db deploy sub-command options
    subcommand_parsers['deploy'].add_argument(
        '-n', '--no-install-collection',
        dest='no_install_collection',
        action='store_true',
        help="Do not install the Ansible collection."
    )
    subcommand_parsers['deploy'].add_argument(
        '-p', '--pre-deploy-ansible',
        dest='pre_deploy_ansible',
        type=argparse.FileType('r'),
        metavar='<pre-deploy-ansible-playbook>',
        help="Pre deploy ansible playbook."
    )
    subcommand_parsers['deploy'].add_argument(
        '-P', '--post-deploy-ansible',
        dest='post_deploy_ansible',
        type=argparse.FileType('r'),
        metavar='<post-deploy-ansible-playbook>',
        help="Post deploy ansible playbook."
    )
    subcommand_parsers['deploy'].add_argument(
        '-S', '--skip-main-playbook',
        dest='skip_main_playbook',
        action='store_true',
        help="Skip main playbook of the reference architecture."
    )
    subcommand_parsers['deploy'].add_argument(
        '--disable-pipelining',
        dest='disable_pipelining',
        action='store_true',
        help="Disable Ansible pipelining."
    )
