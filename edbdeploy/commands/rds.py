import argparse

from ..options import *

# AWS RDS for sub-commands and options
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
        'passwords', help='Display project password'
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
    # aws-rds configure sub-command options
    configure.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    configure.add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOptionRDS.choices,
        default=ReferenceArchitectureOptionRDS.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOptionRDS.help
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
        choices=PgTypeOptionRDS.choices,
        default=PgTypeOptionRDS.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOptionRDS.help
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
        '-r', '--aws-rds-region',
        dest='aws_region',
        choices=AWSRegionOption.choices,
        default=AWSRegionOption.default,
        metavar='<cloud-region>',
        help=AWSRegionOption.help
    )
    configure.add_argument(
        '-i', '--aws-rds-ami-id',
        dest='aws_ami_id',
        type=str,
        default=AWSIAMIDOption.default,
        metavar='<aws-rds-ami-id>',
        help=AWSIAMIDOption.help
    ).completer = aws_ami_id_completer
    configure.add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<aws-rds-spec-file>',
        help="AWS instances specification file, in JSON."
    )
    configure.add_argument(
        '-T', '--t-shirt',
        dest='shirt',
        choices=ShirtSizeOption.choices,
        default=ShirtSizeOption.default,
        metavar='<shirt-size>',
        help=ShirtSizeOption.help
    )
    # aws-rds logs sub-command options
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
    # aws-rds remove sub-command options
    remove.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws-rds show sub-command options
    show.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws-rds display sub-command option
    display.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws-rds passwords sub-command option
    passwords.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws-rds provision sub-command options
    provision.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws-rds destroy sub-command options
    destroy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws-rds deploy sub-command options
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


