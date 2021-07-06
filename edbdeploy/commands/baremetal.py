import argparse

from ..options import *
from .default import default_subcommand_parsers

# Baremetal sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the baremetal
    # command
    available_subcommands = [
        'configure', 'deploy', 'display', 'list', 'logs', 'passwords', 'setup',
        'show', 'specs', 'remove'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )

    # baremetal configure sub-command options
    subcommand_parsers['configure'].add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOption.choices,
        default=ReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOption.help
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
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
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
        '-e', '--efm-version',
        dest='efm_version',
        choices=EFMVersionOption.choices,
        default=EFMVersionOption.default,
        metavar='<efm-version>',
        help=EFMVersionOption.help
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
        metavar='<baremetal-spec-file>',
        help="Baremetal servers specification file, in JSON."
    )
    # baremetal logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # baremetal deploy sub-command options
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
    # baremetal specs sub-command options
    subcommand_parsers['specs'].add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOption.choices,
        default=ReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOption.help
    )
