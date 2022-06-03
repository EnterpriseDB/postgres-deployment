import argparse

from ..options import *
from .default import default_subcommand_parsers

# Azure sub-commands and options
def subcommands(subparser):
    # List of the sub-commands we want to be available for the azure command
    available_subcommands = [
        'configure', 'deploy', 'destroy', 'display', 'list', 'logs',
        'passwords', 'provision', 'setup', 'show', 'specs', 'remove', 'ssh',
        'get_ssh_keys', 'update_route53_key'
    ]

    # Get sub-commands parsers
    subcommand_parsers = default_subcommand_parsers(
        subparser, available_subcommands
    )

    # azure configure sub-command options
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
        '-v', '--pg-version',
        dest='postgres_version',
        choices=POTPgVersionOption.choices,
        default=POTPgVersionOption.default,
        metavar='<postgres-version>',
        help=POTPgVersionOption.help
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
        metavar='<azure-spec-file>',
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
        '-f', '--force',
        dest='force_configure',
        action='store_true',
        help="Force project configuration."
    )
    # azure logs sub-command options
    subcommand_parsers['logs'].add_argument(
        '-t', '--tail',
        dest='tail',
        action='store_true',
        help="Do not stop at the end of file."
    )
    # azure deploy sub-command options
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
