import argparse

from ..options import *
from .default import default_subcommand_parsers

# GCloudSQL sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the gcloud-sql
    # command
    available_subcommands = [
        'configure', 'deploy', 'destroy', 'display', 'list', 'logs',
        'passwords', 'provision', 'setup', 'show', 'specs', 'remove'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )

    # gcloud-sql configure sub-command options
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
        choices=PgTypeOptionGCloudSQL.choices,
        default=PgTypeOptionGCloudSQL.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOptionGCloudSQL.help
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
        '-r', '--gcloud-region',
        dest='gcloud_region',
        choices=GCloudRegionOption.choices,
        default=GCloudRegionOption.default,
        metavar='<cloud-region>',
        help=GCloudRegionOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<gcloud-spec-file>',
        help="GCloud instances specification file, in JSON."
    )
    subcommand_parsers['configure'].add_argument(
        '-c', '--gcloud-credentials',
        dest='gcloud_credentials',
        type=argparse.FileType('r'),
        default=GCloudCredentialsOption.default(),
        metavar='<gcloud-credentials-json-file>',
        help=GCloudCredentialsOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-p', '--gcloud-project-id',
        dest='gcloud_project_id',
        required=True,
        type=str,
        metavar='<gcloud-project-id>',
        help="GCloud project ID"
    ).completer = gcloud_project_id_completer
    subcommand_parsers['configure'].add_argument(
        '-T', '--t-shirt',
        dest='shirt',
        choices=ShirtSizeOption.choices,
        default=ShirtSizeOption.default,
        metavar='<shirt-size>',
        help=ShirtSizeOption.help
    )
    # gcloud-sql logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # gcloud-sql deploy sub-command options
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
