import argparse

from ..options import *
from .default import default_subcommand_parsers

# AWS sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the aws command
    available_subcommands = [
        'configure', 'deploy', 'destroy', 'display', 'list', 'logs',
        'passwords', 'provision', 'show', 'specs', 'setup', 'remove', 'ssh',
        'get_ssh_keys', 'update_route53_key'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )
    # aws configure sub-command options
    subcommand_parsers['configure'].add_argument(
        '-a', '--reference-architecture',
        dest='reference_architecture',
        choices=POTReferenceArchitectureOption.choices,
        default=POTReferenceArchitectureOption.default,
        metavar='<ref-arch-code>',
        help=POTReferenceArchitectureOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '--tpaexec-bin',
        dest='tpaexec_bin',
        required=False,
        type=str,
        metavar='<tpaexec-bin>',
        help="TPAexec bin directory location"
    )
    subcommand_parsers['configure'].add_argument(
        '--tpaexec-subscription-token',
        dest='tpa_subscription_token',
        required=False,
        type=str,
        metavar='<tpaexec-subscription-token>',
        help="EDB TPAexec subscription token"
    )
    subcommand_parsers['configure'].add_argument(
        '--route53-access-key',
        dest='route53_access_key',
        required=True,
        type=str,
        metavar='<route53-acccess-key>',
        help="Route53 Access Key"
    )
    subcommand_parsers['configure'].add_argument(
        '--route53-secret',
        dest='route53_secret',
        required=True,
        type=str,
        metavar='<route53-secret>',
        help="Route53 Secret"
    )
    subcommand_parsers['configure'].add_argument(
        '--route53-session-token',
        dest='route53_session_token',
        required=False,
        type=str,
        default="",
        metavar='<route53-session-token>',
        help="Route53 Session Token"
    )
    subcommand_parsers['configure'].add_argument(
        '--email-id',
        dest='email_id',
        required=True,
        type=str,
        metavar='<email-id>',
        help="Email Id"
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
        choices=POTPgTypeOption.choices,
        default=POTPgTypeOption.default,
        metavar='<postgres-engine-type>',
        help=POTPgTypeOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-r', '--aws-region',
        dest='aws_region',
        choices=AWSRegionOption.choices,
        default=AWSRegionOption.default,
        metavar='<cloud-region>',
        help=AWSRegionOption.help
    )
    subcommand_parsers['configure'].add_argument(
        '-i', '--aws-ami-id',
        dest='aws_ami_id',
        type=str,
        default=AWSIAMIDOption.default,
        metavar='<aws-ami-id>',
        help=AWSIAMIDOption.help
    ).completer = aws_ami_id_completer
    subcommand_parsers['configure'].add_argument(
        '-s', '--spec',
        dest='spec_file',
        type=argparse.FileType('r'),
        metavar='<aws-spec-file>',
        help="AWS instances specification file, in JSON."
    )
    subcommand_parsers['configure'].add_argument(
        '-f', '--force',
        dest='force_configure',
        action='store_true',
        help="Force project configuration."
    )
    # aws logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # aws deploy sub-command options
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
    subcommand_parsers['ssh'].add_argument(
        metavar='<host-name>',
        dest='host',
        help="Node hostname"
    )
    subcommand_parsers['update_route53_key'].add_argument(
        '--route53-access-key',
        dest='route53_access_key',
        required=True,
        type=str,
        metavar='<route53-acccess-key>',
        help="Route53 Access Key"
    )
    subcommand_parsers['update_route53_key'].add_argument(
        '--route53-secret',
        dest='route53_secret',
        required=True,
        type=str,
        metavar='<route53-secret>',
        help="Route53 Secret"
    )
    subcommand_parsers['update_route53_key'].add_argument(
        '--route53-session-token',
        dest='route53_session_token',
        required=False,
        type=str,
        default="",
        metavar='<route53-session-token>',
        help="Route53 Session Token"
    )
