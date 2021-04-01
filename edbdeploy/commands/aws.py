import argparse

from ..options import *

# AWS sub-commands and options
def subcommands(subparser):
    configure = subparser.add_parser(
        'configure', help='Project configuration'
    )
    provision = subparser.add_parser(
        'provision', help='Machines provisioning'
    )
    destroy = subparser.add_parser(
        'destroy', help='Machines destruction'
    )
    deploy = subparser.add_parser(
        'deploy', help='Postgres deployment'
    )
    show = subparser.add_parser(
        'show', help='Show configuration'
    )
    display = subparser.add_parser(
        'display', help='Display project details'
    )
    passwords = subparser.add_parser(
        'passwords', help='Display project passwords'
    )
    list = subparser.add_parser(
        'list', help='List projects'
    )
    specs = subparser.add_parser(
        'specs', help='Show Cloud default specifications'
    )
    logs = subparser.add_parser(
        'logs', help='Show project logs'
    )
    remove = subparser.add_parser(
        'remove', help='Remove project'
    )
    # aws configure sub-command options
    configure.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    configure.add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOption.choices,
        default=ReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOption.help
    )
    configure.add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    ).completer = edb_credentials_completer
    configure.add_argument(
        '-o', '--os',
        dest='operating_system',
        choices=OSOption.choices,
        default=OSOption.default,
        metavar='<operating-system>',
        help=OSOption.help
    )
    configure.add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
    )
    configure.add_argument(
        '-v', '--pg-version',
        dest='postgres_version',
        choices=PgVersionOption.choices,
        default=PgVersionOption.default,
        metavar='<postgres-version>',
        help=PgVersionOption.help
    )
    configure.add_argument(
        '-e', '--efm-version',
        dest='efm_version',
        choices=EFMVersionOption.choices,
        default=EFMVersionOption.default,
        metavar='<efm-version>',
        help=EFMVersionOption.help
    )
    configure.add_argument(
        '-k', '--ssh-pub-key',
        dest='ssh_pub_key',
        type=argparse.FileType('r'),
        default=SSHPubKeyOption.default(),
        metavar='<ssh-public-key-file>',
        help=SSHPubKeyOption.help
    )
    configure.add_argument(
        '-K', '--ssh-private-key',
        dest='ssh_priv_key',
        type=argparse.FileType('r'),
        default=SSHPrivKeyOption.default(),
        metavar='<ssh-private-key-file>',
        help=SSHPrivKeyOption.help
    )
    configure.add_argument(
        '-r', '--aws-region',
        dest='aws_region',
        choices=AWSRegionOption.choices,
        default=AWSRegionOption.default,
        metavar='<cloud-region>',
        help=AWSRegionOption.help
    )
    configure.add_argument(
        '-i', '--aws-ami-id',
        dest='aws_ami_id',
        type=str,
        default=AWSIAMIDOption.default,
        metavar='<aws-ami-id>',
        help=AWSIAMIDOption.help
    ).completer = aws_ami_id_completer
    configure.add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<aws-spec-file>',
        help="AWS instances specification file, in JSON."
    )
    # aws logs sub-command options
    logs.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    logs.add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # aws remove sub-command options
    remove.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws show sub-command options
    show.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws display sub-command option
    display.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws password sub-command option
    passwords.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws provision sub-command options
    provision.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws destroy sub-command options
    destroy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws deploy sub-command options
    deploy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    deploy.add_argument(
        '-n', '--no-install-collection',
        dest='no_install_collection',
        action='store_true',
        help="Do not install the Ansible collection."
    )
