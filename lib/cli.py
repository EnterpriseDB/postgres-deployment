import argparse
import os
import re
import sys
import textwrap


class ReferenceArchitectureOption:
    choices = ['EDB-RA-1', 'EDB-RA-2', 'EDB-RA-3']
    default = 'EDB-RA-1'
    help = textwrap.dedent("""
        Reference architecture code name. Allowed values are: EDB-RA-1 for a
        single Postgres node deployment with one backup server and one PEM
        monitoring server, EDB-RA-2 for a 3 Postgres nodes deployment with
        quorum base synchronous replication and automatic failover, one backup
        server and one PEM monitoring server, and EDB-RA-3 for extending
        EDB-RA-2 with 3 PgPoolII nodes. Default: %(default)s
    """)


class OSOption:
    choices = ['CentOS7', 'CentOS8', 'RedHat7', 'RedHat8']
    default = 'CentOS8'
    help = textwrap.dedent("""
        Operating system. Allowed values are: CentOS7, CentOS8, RedHat7 and
        RedHat8. Default: %(default)s
    """)


class PgVersionOption:
    choices = ['11', '12', '13']
    default = '13'
    help = textwrap.dedent("""
        PostgreSQL or EPAS version. Allowed values are: 11, 12 and 13.
        Default: %(default)s
    """)


class PgTypeOption:
    choices = ['PG', 'EPAS']
    default = 'PG'
    help = textwrap.dedent("""
        Postgres engine type. Allowed values are: PG for PostgreSQL, EPAS for
        EDB Postgres Advanced Server. Default: %(default)s
    """)


class SSHPubKeyOption:

    help = textwrap.dedent("""
        SSH public key path to use. Default: %(default)s
    """)

    @staticmethod
    def default():
        home = os.path.expanduser("~")
        pub_key_path = os.path.join(home, '.ssh', 'id_rsa.pub')
        if os.path.exists(pub_key_path):
            return pub_key_path


class SSHPrivKeyOption:

    help = textwrap.dedent("""
        SSH private key path to use. Default: %(default)s
    """)

    @staticmethod
    def default():
        home = os.path.expanduser("~")
        priv_key_path = os.path.join(home, '.ssh', 'id_rsa')
        if os.path.exists(priv_key_path):
            return priv_key_path


# Cloud specific options
class AWSRegionOption:
    choices = ['us-east-1', 'us-east-2', 'us-west-1', 'us-west-2']
    default = 'us-east-1'
    help = textwrap.dedent("""
        AWS region. Allowed values are us-east-1, us-east-2, us-west-1 and
        us-west-2. Default: %(default)s
    """)


class AWSIAMIDOption:
    default = ''
    help = textwrap.dedent("""
        AWS Image ID. Default: %(default)s
    """)


class AWSSpecFileOption:

    help = textwrap.dedent("""
        AWS instances specification file, in JSON. Default: %(default)s
    """)

    @staticmethod
    def default():
        spec_file_path = os.path.join(
            os.path.dirname(os.path.relpath(__file__)),
            'spec',
            'aws.json'
        )
        if os.path.exists(spec_file_path):
            return spec_file_path


class AzureRegionOption:
    choices = ['centralus', 'eastus', 'eastus2', 'westus', 'westcentralus',
               'westus2', 'northcentralus', 'southcentralus']
    default = 'eastus'
    help = textwrap.dedent("""
        Azure region. Allowed values are centralus, eastus, eastus2, westus,
        westcentralus, westus2, northcentralus and southcentralus.
        Default: %(default)s
    """)


class GCloudRegionOption:
    choices = ['us-central1', 'us-east1', 'us-east4', 'us-west1', 'us-west2',
               'us-west3', 'us-west4']
    default = 'us-east1'
    help = textwrap.dedent("""
        GCloud region. Allowed values are us-central1, us-east1, us-east4,
        us-west1, us-west2, us-west3 and us-west4. Default: %(default)s
    """)


class GCloudCredentialsOption:

    help = textwrap.dedent("""
        GCloud credentials file (JSON) to use. Default: %(default)s
    """)

    @staticmethod
    def default():
        home = os.path.expanduser("~")
        credential_file = os.path.join(home, 'accounts.json')
        if os.path.exists(credential_file):
            return credential_file


def EDBCredentialsType(value):
    p = re.compile(r"^([^:]+):(.+)$")
    if not p.match(value):
        raise argparse.ArgumentTypeError(
            "EDB Credentials does not match \"<username>:<password>\""
        )
    return value


class CLIParser(argparse.ArgumentParser):
    def error(self, message):
        if message == "too few arguments":
            self.print_help()
        sys.stderr.write('error: %s\n' % message)
        sys.exit(2)


# AWS sub-commands and options
def aws_subcommands(aws_subparser):
    aws_configure = aws_subparser.add_parser(
        'configure', help='Project configuration'
    )
    aws_provision = aws_subparser.add_parser(
        'provision', help='Machines provisioning'
    )
    aws_destroy = aws_subparser.add_parser(
        'destroy', help='Machines destruction'
    )
    aws_deploy = aws_subparser.add_parser(
        'deploy', help='Postgres deployment'
    )
    aws_show = aws_subparser.add_parser(
        'show', help='Show configuration'
    )
    aws_update = aws_subparser.add_parser(
        'update', help='Update configuration'
    )
    aws_list = aws_subparser.add_parser(
        'list', help='List projects'
    )
    aws_logs = aws_subparser.add_parser(
        'logs', help='Show project logs'
    )
    aws_remove = aws_subparser.add_parser(
        'remove', help='Remove project'
    )
    # aws configure sub-command options
    aws_configure.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    aws_configure.add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOption.choices,
        default=ReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOption.help
    )
    aws_configure.add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    )
    aws_configure.add_argument(
        '-o', '--os',
        dest='operating_system',
        choices=OSOption.choices,
        default=OSOption.default,
        metavar='<operating-system>',
        help=OSOption.help
    )
    aws_configure.add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
    )
    aws_configure.add_argument(
        '-v', '--pg-version',
        dest='postgres_version',
        choices=PgVersionOption.choices,
        default=PgVersionOption.default,
        metavar='<postgres-version>',
        help=PgVersionOption.help
    )
    aws_configure.add_argument(
        '-k', '--ssh-pub-key',
        dest='ssh_pub_key',
        type=argparse.FileType('r'),
        default=SSHPubKeyOption.default(),
        metavar='<ssh-public-key-file>',
        help=SSHPubKeyOption.help
    )
    aws_configure.add_argument(
        '-K', '--ssh-private-key',
        dest='ssh_priv_key',
        type=argparse.FileType('r'),
        default=SSHPrivKeyOption.default(),
        metavar='<ssh-private-key-file>',
        help=SSHPrivKeyOption.help
    )
    aws_configure.add_argument(
        '-r', '--aws-region',
        dest='aws_region',
        choices=AWSRegionOption.choices,
        default=AWSRegionOption.default,
        metavar='<cloud-region>',
        help=AWSRegionOption.help
    )
    aws_configure.add_argument(
        '-i', '--aws-ami-id',
        dest='aws_ami_id',
        type=str,
        default=AWSIAMIDOption.default,
        metavar='<aws-ami-id>',
        help=AWSIAMIDOption.help
    )
    aws_configure.add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        default=AWSSpecFileOption.default(),
        metavar='<aws-spec-file>',
        help=AWSSpecFileOption.help
    )
    # aws log sub-command options
    aws_logs.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    aws_logs.add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # aws remove sub-command options
    aws_remove.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # aws show sub-command options
    aws_show.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # aws provision sub-command options
    aws_provision.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # aws destroy sub-command options
    aws_destroy.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # aws deploy sub-command options
    aws_deploy.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    aws_deploy.add_argument(
        '-n', '--no-install-collection',
        dest='no_install_collection',
        action='store_true',
        help="Do not install the Ansible collection."
    )

# Azure sub-commands and options
def azure_subcommands(azure_subparser):
    azure_configure = azure_subparser.add_parser(
        'configure', help='Project configuration'
    )
    azure_provision = azure_subparser.add_parser(
        'provision', help='Machines provisionning'
    )
    azure_destroy = azure_subparser.add_parser(
        'destroy', help='Machines destruction'
    )
    azure_deploy = azure_subparser.add_parser(
        'deploy', help='Postgres deployment'
    )
    azure_show = azure_subparser.add_parser(
        'show', help='Show configuration'
    )
    azure_update = azure_subparser.add_parser(
        'update', help='Update configuration'
    )
    azure_list = azure_subparser.add_parser(
        'list', help='List Terraform projects'
    )
    azure_switch = azure_subparser.add_parser(
        'switch', help='Switch to another Terraform project'
    )
    azure_log = azure_subparser.add_parser(
        'log', help='Show project logs'
    )
    azure_remove = azure_subparser.add_parser(
        'remove', help='Remove project'
    )
    # azure configure sub-command options
    azure_configure.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Terraform project name'
    )
    azure_configure.add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOption.choices,
        default=ReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOption.help
    )
    azure_configure.add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    )
    azure_configure.add_argument(
        '-o', '--os',
        dest='operating_system',
        choices=OSOption.choices,
        default=OSOption.default,
        metavar='<operating-system>',
        help=OSOption.help
    )
    azure_configure.add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
    )
    azure_configure.add_argument(
        '-v', '--pg-version',
        dest='postgres_version',
        choices=PgVersionOption.choices,
        default=PgVersionOption.default,
        metavar='<postgres-version>',
        help=PgVersionOption.help
    )
    azure_configure.add_argument(
        '-k', '--ssh-pub-key',
        dest='ssh_pub_key',
        type=argparse.FileType('r'),
        default=SSHPubKeyOption.default(),
        metavar='<ssh-public-key-file>',
        help=SSHPubKeyOption.help
    )
    azure_configure.add_argument(
        '-K', '--ssh-private-key',
        dest='ssh_priv_key',
        type=argparse.FileType('r'),
        default=SSHPrivKeyOption.default(),
        metavar='<ssh-private-key-file>',
        help=SSHPrivKeyOption.help
    )
    azure_configure.add_argument(
        '-r', '--region',
        dest='region',
        choices=AzureRegionOption.choices,
        default=AzureRegionOption.default,
        metavar='<cloud-region>',
        help=AzureRegionOption.help
    )
    # azure log sub-command options
    azure_log.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # azure remove sub-command options
    azure_remove.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # azure show sub-command options
    azure_show.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )


# GCloud sub-commands and options
def gcloud_subcommands(gcloud_subparser):
    gcloud_configure = gcloud_subparser.add_parser(
        'configure', help='Project configuration'
    )
    gcloud_provision = gcloud_subparser.add_parser(
        'provision', help='Machines provisionning'
    )
    gcloud_destroy = gcloud_subparser.add_parser(
        'destroy', help='Machines destruction'
    )
    gcloud_deploy = gcloud_subparser.add_parser(
        'deploy', help='Postgres deployment'
    )
    gcloud_show = gcloud_subparser.add_parser(
        'show', help='Show configuration'
    )
    gcloud_update = gcloud_subparser.add_parser(
        'update', help='Update configuration'
    )
    gcloud_list = gcloud_subparser.add_parser(
        'list', help='List projects'
    )
    gcloud_log = gcloud_subparser.add_parser(
        'log', help='Show project logs'
    )
    gcloud_remove = gcloud_subparser.add_parser(
        'remove', help='Remove project'
    )
    # gcloud configure sub-command options
    gcloud_configure.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Terraform project name'
    )
    gcloud_configure.add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=ReferenceArchitectureOption.choices,
        default=ReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=ReferenceArchitectureOption.help
    )
    gcloud_configure.add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    )
    gcloud_configure.add_argument(
        '-o', '--os',
        dest='operating_system',
        choices=OSOption.choices,
        default=OSOption.default,
        metavar='<operating-system>',
        help=OSOption.help
    )
    gcloud_configure.add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
    )
    gcloud_configure.add_argument(
        '-v', '--pg-version',
        dest='postgres_version',
        choices=PgVersionOption.choices,
        default=PgVersionOption.default,
        metavar='<postgres-version>',
        help=PgVersionOption.help
    )
    gcloud_configure.add_argument(
        '-k', '--ssh-pub-key',
        dest='ssh_pub_key',
        type=argparse.FileType('r'),
        default=SSHPubKeyOption.default(),
        metavar='<ssh-public-key-file>',
        help=SSHPubKeyOption.help
    )
    gcloud_configure.add_argument(
        '-K', '--ssh-private-key',
        dest='ssh_priv_key',
        type=argparse.FileType('r'),
        default=SSHPrivKeyOption.default(),
        metavar='<ssh-private-key-file>',
        help=SSHPrivKeyOption.help
    )
    gcloud_configure.add_argument(
        '-r', '--region',
        dest='region',
        choices=GCloudRegionOption.choices,
        default=GCloudRegionOption.default,
        metavar='<cloud-region>',
        help=GCloudRegionOption.help
    )
    gcloud_configure.add_argument(
        '-c', '--credentials',
        dest='gcloud_credentials',
        type=argparse.FileType('r'),
        default=GCloudCredentialsOption.default(),
        metavar='<gcloud-credentials-json-file>',
        help=GCloudCredentialsOption.help
    )
    # gcloud log sub-command options
    gcloud_log.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # gcloud remove sub-command options
    gcloud_remove.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )
    # gcloud show sub-command options
    gcloud_show.add_argument(
        'project', type=str, metavar='<project-name>',
        help='Project name'
    )

def parse():
    parser = CLIParser(
        description='EDB deployment script for aws, azure and gcloud'
    )
    subparsers = parser.add_subparsers(
        title='Cloud provider', dest='cloud', metavar='<cloud>'
    )

    # Cloud commands
    aws = subparsers.add_parser('aws', help='AWS Cloud')
    azure = subparsers.add_parser('azure', help='Azure Cloud')
    gcloud = subparsers.add_parser('gcloud', help='Google Cloud')

    # Sub-commands
    # AWS
    aws_subparser = aws.add_subparsers(
        title='AWS sub-commands', dest='sub_command', metavar='<sub-command>'
    )
    aws_subcommands(aws_subparser)
    # Azure
    azure_subparser = azure.add_subparsers(
        title='Azure sub-commands', dest='sub_command', metavar='<sub-command>'
    )
    azure_subcommands(azure_subparser)
    # GCloud
    gcloud_subparser = gcloud.add_subparsers(
        title='GCloud sub-commands',
        dest='sub_command',
        metavar='<sub-command>'
    )
    gcloud_subcommands(gcloud_subparser)

    # Parse the arguments and options
    env = parser.parse_args()

    # Check if the <cloud> argument is set
    if not getattr(env, 'cloud'):
        parser.print_help()
        sys.stderr.write('error: too few arguments\n')
        sys.exit(2)
    # Check if the <sub-command> argument is set
    if not getattr(env, 'sub_command'):
        if env.cloud == 'aws':
            aws.print_help()
        elif env.cloud == 'azure':
            azure.print_help()
        elif env.cloud == 'gcloud':
            gcloud.print_help()
        sys.stderr.write('error: too few arguments\n')
        sys.exit(2)

    return env
