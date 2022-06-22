import argparse

from ..options import *
from .default import default_subcommand_parsers

# Virtualbox sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the virtualbox
    # command
    available_subcommands = [
        'configure', 'provision', 'deploy', 'destroy', 'remove', 'logs', 'list',
        'display', 'ssh', 'specs'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )

    # virtualbox deploy sub-command options
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
        '-o', '--os',
        dest='operating_system',
        choices=VirtualBoxOSOption.choices,
        default=VirtualBoxOSOption.default,
        metavar='<operating-system>',
        help=OSOption.help
    )
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
        choices=EFMVersionOptionVirtualBox.choices,
        default=EFMVersionOptionVirtualBox.default,
        metavar='<efm-version>',
        help=EFMVersionOptionVirtualBox.help
    )
    subcommand_parsers['configure'].add_argument(
        '-f', '--force',
        dest='force_configure',
        action='store_true',
        help="Force project configuration."
    )
    subcommand_parsers['configure'].add_argument(
        '--use-hostname',
        dest='use_hostname',
        choices=UseHostnameOption.choices,
        default=UseHostnameOption.default,
        metavar='<use-hostname>',
        help=UseHostnameOption.help
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
        metavar='<spec-file>',
        help="VirtualBox instances specification file, in JSON."
    )

    subcommand_parsers['configure'].add_argument(
        '-m', '--mem-size',
        dest='mem_size',
        required=True,
        choices=MemSizeOptionsVirtualBox.choices,
        default=MemSizeOptionsVirtualBox.default,
        help="Amount of memory to assign"
    )

    subcommand_parsers['configure'].add_argument(
        '-c', '--cpu-count',
        dest='cpu_count',
        required=True,
        choices=CPUCountOptionsVirtualBox.choices,
        default=CPUCountOptionsVirtualBox.default,
        help="Number of CPUS to configure"
    )

    # virtualbox deploy sub-command options
    subcommand_parsers['provision'].add_argument(
        '-S', '--skip-main-playbook',
        dest='skip_main_playbook',
        action='store_true',
        help="Skip main playbook of the reference architecture."
    )

    # virtualbox deploy sub-command options
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

    # virtualbox deploy sub-command options
    subcommand_parsers['destroy'].add_argument(
        '-S', '--skip-main-playbook',
        dest='skip_main_playbook',
        action='store_true',
        help="Skip main playbook of the reference architecture."
    )

    # virtualbox logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    subcommand_parsers['deploy'].add_argument(
        '--disable-pipelining',
        dest='disable_pipelining',
        action='store_true',
        help="Disable Ansible pipelining."
    )
    subcommand_parsers['ssh'].add_argument(
        metavar='<host-name>',
        dest='host',
        help="Node hostname"
    )
    subcommand_parsers['specs'].add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOption.choices,
        default=ReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOption.help
    )
