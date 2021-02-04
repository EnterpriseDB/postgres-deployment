import argcomplete
import argparse
import os
import re
import sys
import textwrap

from . import __version__
from .project import Project

class PgTypeOption:
    choices = ['PG', 'EPAS']
    default = 'EPAS'
    help = textwrap.dedent("""
        Postgres engine type. Allowed values are: PG for PostgreSQL, EPAS for
        EDB Postgres Advanced Server. Default: %(default)s
    """)



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


def ProjectType(value):
    p = re.compile(r"^[a-z0-9]{3,12}$")
    if not p.match(value):
        raise argparse.ArgumentTypeError(
            "Project name should only contain lower alphanumeric characters, "
            "length must be between 3 and 12"
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
    aws_display = aws_subparser.add_parser(
        'display', help='Display project details'
    )
    aws_passwords = aws_subparser.add_parser(
        'passwords', help='Display project password'
    )
    aws_list = aws_subparser.add_parser(
        'list', help='List projects'
    )
    aws_specs = aws_subparser.add_parser(
        'specs', help='Show Cloud default specifications'
    )
    aws_logs = aws_subparser.add_parser(
        'logs', help='Show project logs'
    )
    aws_remove = aws_subparser.add_parser(
        'remove', help='Remove project'
    )
    # aws configure sub-command options
    aws_configure.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    aws_configure.add_argument(
        '--route53-access-key',
        dest='route53_access_key',
        required=True,
        type=str,
        metavar='<route53-acccess-key>',
        help="Route53 Access Key"
    )
    aws_configure.add_argument(
        '--route53-secret',
        dest='route53_secret',
        required=True,
        type=str,
        metavar='<route53-secret>',
        help="Route53 Secret"
    )
    aws_configure.add_argument(
        '--email-id',
        dest='email_id',
        required=True,
        type=str,
        metavar='<email-id>',
        help="Email Id"
    )
    aws_configure.add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    ).completer = edb_credentials_completer
    aws_configure.add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
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
    ).completer = aws_ami_id_completer
    aws_configure.add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<aws-spec-file>',
        help="AWS instances specification file, in JSON."
    )
    # aws logs sub-command options
    aws_logs.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    aws_logs.add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # aws remove sub-command options
    aws_remove.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws show sub-command options
    aws_show.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws display sub-command options
    aws_display.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws password sub-command option
    aws_passwords.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws provision sub-command options
    aws_provision.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws destroy sub-command options
    aws_destroy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # aws deploy sub-command options
    aws_deploy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
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
    azure_display = azure_subparser.add_parser(
        'display', help='Display project details'
    )
    azure_passwords = azure_subparser.add_parser(
        'passwords', help='Display project passwords'
    )
    azure_list = azure_subparser.add_parser(
        'list', help='List projects'
    )
    azure_specs = azure_subparser.add_parser(
        'specs', help='Show Cloud default specifications'
    )
    azure_logs = azure_subparser.add_parser(
        'logs', help='Show project logs'
    )
    azure_remove = azure_subparser.add_parser(
        'remove', help='Remove project'
    )
    # azure configure sub-command options
    azure_configure.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Terraform project name'
    ).completer = project_name_completer
    azure_configure.add_argument(
        '--route53-access-key',
        dest='route53_access_key',
        required=True,
        type=str,
        metavar='<route53-acccess-key>',
        help="Route53 Access Key"
    )
    azure_configure.add_argument(
        '--route53-secret',
        dest='route53_secret',
        required=True,
        type=str,
        metavar='<route53-secret>',
        help="Route53 Secret"
    )
    azure_configure.add_argument(
        '--email-id',
        dest='email_id',
        required=True,
        type=str,
        metavar='<email-id>',
        help="Email Id"
    )
    azure_configure.add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    ).completer = edb_credentials_completer
    azure_configure.add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
    )
    azure_configure.add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<azure-spec-file>',
        help="Azure instances specification file, in JSON."
    )
    azure_configure.add_argument(
        '-r', '--azure-region',
        dest='azure_region',
        choices=AzureRegionOption.choices,
        default=AzureRegionOption.default,
        metavar='<cloud-region>',
        help=AzureRegionOption.help
    )
    # azure logs sub-command options
    azure_logs.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = edb_credentials_completer
    azure_logs.add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # azure remove sub-command options
    azure_remove.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # azure show sub-command options
    azure_show.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # azure display sub-command options
    azure_display.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # azure password sub-command options
    azure_passwords.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # azure provision sub-command options
    azure_provision.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # azure destroy sub-command options
    azure_destroy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # azure deploy sub-command options
    azure_deploy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    azure_deploy.add_argument(
        '-n', '--no-install-collection',
        dest='no_install_collection',
        action='store_true',
        help="Do not install the Ansible collection."
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
    gcloud_display = gcloud_subparser.add_parser(
        'display', help='Display project details'
    )
    gcloud_passwords = gcloud_subparser.add_parser(
        'passwords', help='Display project passwords'
    )
    gcloud_list = gcloud_subparser.add_parser(
        'list', help='List projects'
    )
    gcloud_specs = gcloud_subparser.add_parser(
        'specs', help='Show Cloud default specifications'
    )
    gcloud_logs = gcloud_subparser.add_parser(
        'logs', help='Show project logs'
    )
    gcloud_remove = gcloud_subparser.add_parser(
        'remove', help='Remove project'
    )
    # gcloud configure sub-command options
    gcloud_configure.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Terraform project name'
    ).completer = edb_credentials_completer
    gcloud_configure.add_argument(
        '--route53-access-key',
        dest='route53_access_key',
        required=True,
        type=str,
        metavar='<route53-acccess-key>',
        help="Route53 Access Key"
    )
    gcloud_configure.add_argument(
        '--route53-secret',
        dest='route53_secret',
        required=True,
        type=str,
        metavar='<route53-secret>',
        help="Route53 Secret"
    )
    gcloud_configure.add_argument(
        '--email-id',
        dest='email_id',
        required=True,
        type=str,
        metavar='<email-id>',
        help="Email Id"
    )
    gcloud_configure.add_argument(
        '-u', '--edb-credentials',
        dest='edb_credentials',
        required=True,
        type=EDBCredentialsType,
        metavar='"<username>:<password>"',
        help="EDB Packages repository credentials."
    ).completer = edb_credentials_completer
    gcloud_configure.add_argument(
        '-t', '--pg-type',
        dest='postgres_type',
        choices=PgTypeOption.choices,
        default=PgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=PgTypeOption.help
    )
    gcloud_configure.add_argument(
        '-r', '--gcloud-region',
        dest='gcloud_region',
        choices=GCloudRegionOption.choices,
        default=GCloudRegionOption.default,
        metavar='<cloud-region>',
        help=GCloudRegionOption.help
    )
    gcloud_configure.add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<gcloud-spec-file>',
        help="GCloud instances specification file, in JSON."
    )
    gcloud_configure.add_argument(
        '-c', '--gcloud-credentials',
        dest='gcloud_credentials',
        type=argparse.FileType('r'),
        default=GCloudCredentialsOption.default(),
        metavar='<gcloud-credentials-json-file>',
        help=GCloudCredentialsOption.help
    )
    gcloud_configure.add_argument(
        '-p', '--gcloud-project-id',
        dest='gcloud_project_id',
        required=True,
        type=str,
        metavar='<gcloud-project-id>',
        help="GCloud project ID"
    ).completer = edb_credentials_completer
    # gcloud logs sub-command options
    gcloud_logs.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    gcloud_logs.add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # gcloud remove sub-command options
    gcloud_remove.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # gcloud show sub-command options
    gcloud_show.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # gcloud display sub-command options
    gcloud_display.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # gcloud password sub-command options
    gcloud_passwords.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # gcloud provision sub-command options
    gcloud_provision.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # gcloud destroy sub-command options
    gcloud_destroy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    # gcloud deploy sub-command options
    gcloud_deploy.add_argument(
        'project', type=ProjectType, metavar='<project-name>',
        help='Project name'
    ).completer = project_name_completer
    gcloud_deploy.add_argument(
        '-n', '--no-install-collection',
        dest='no_install_collection',
        action='store_true',
        help="Do not install the Ansible collection."
    )

# Argcomplete completer
def project_name_completer(prefix, parsed_args, **kwargs):
    cloud = parsed_args.cloud
    sub_command = parsed_args.sub_command
    if sub_command == 'configure':
        return ("PROJECT_NAME",)
    else:
        projects_path = os.path.join(Project.projects_root_path, cloud)
        if not os.path.exists(projects_path):
            return ("PROJECT_NAME",)
        return (pname for pname in os.listdir(projects_path))

def edb_credentials_completer(prefix, parsed_args, **kwargs):
    return ("USERNAME:PASSWORD",)

def aws_ami_id_completer(prefix, parsed_args, **kwargs):
    return ("AWS_AMI_ID",)

def gcloud_project_id_completer(prefix, parsed_args, **kwargs):
    return ("GCLOUD_PROJECT_ID",)

def parse():
    parser = CLIParser(
        description='EDB deployment script for aws, azure and gcloud'
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
            aws.print_help()
        elif env.cloud == 'azure':
            azure.print_help()
        elif env.cloud == 'gcloud':
            gcloud.print_help()
        sys.stderr.write('error: too few arguments\n')
        sys.exit(2)

    return env
