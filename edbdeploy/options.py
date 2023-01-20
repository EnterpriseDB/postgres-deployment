import os
import re
import argparse
import textwrap
from .project import Project


class ReferenceArchitectureOption:
    choices = ['EDB-RA-1', 'EDB-RA-2', 'EDB-RA-3', 'HammerDB-TPROC-C']

    default = 'EDB-RA-1'
    help = textwrap.dedent("""
        Reference architecture code name. Allowed values are: EDB-RA-1 for a
        single Postgres node deployment with one backup server and one PEM
        monitoring server, EDB-RA-2 for a 3 Postgres nodes deployment with
        quorum base synchronous replication and automatic failover, one backup
        server and one PEM monitoring server, EDB-RA-3 for extending EDB-RA-2
        with 3 PgPoolII nodes, and HammerDB-TPROC-C for benchmarking 2-tier
        client-server architectures with an OLTP workload.  Default: %(default)s
    """)


class POTReferenceArchitectureOption:
    choices = ['EDB-RA', 'EDB-Always-On-Platinum', 'EDB-Always-On-Silver']

    default = 'EDB-RA'
    help = textwrap.dedent("""
        Reference architecture code name. Allowed values are: EDB-RA for
        a 3 Postgres nodes deployment with quorum base synchronous replication
        and automatic failover, one backup server and one PEM monitoring
        server, EDB-Always-On-Platinum for deployment 6 Postgres nodes and one
        witness node with BDR EE, two backup servers, 4 Pgbouncer/HAproxy
        servers and one PEM monitoring server, EDB-Always-On-Silver for 3
        Postgres nodes with BDR EE, 2 Pgbouncer/HAproxy servers and one PEM
        monitoring server.
        Default: %(default)s
    """)

class ReferenceArchitectureOptionDBaaS:
    choices = ['HammerDB-DBaaS']
    default = 'HammerDB-DBaaS'
    help = textwrap.dedent("""
        Reference architecture code name. Allowed values are: HammerDB-DBaaS
        for benchmarking any DBaaS offering for benchmarking 2-tier
        client-server architectures with and OLTP workload. Default:
        %(default)s
    """)


class OSOption:
    choices = ['CentOS7', 'RedHat7', 'RedHat8', 'RockyLinux8']
    default = 'RockyLinux8'
    help = textwrap.dedent("""
        Operating system. Allowed values are: CentOS7, RedHat7, RedHat8 and
        RockyLinux8. Default: %(default)s
    """)


class VMWareOSOption:
    choices = ['RockyLinux8']
    default = 'RockyLinux8'
    help = textwrap.dedent("""
        Operating system. Allowed values are: RockyLinux8. Default: %(default)s
    """)

class VirtualBoxOSOption:
    choices = ['RockyLinux8']
    default = 'RockyLinux8'
    help = textwrap.dedent("""
        Operating system. Allowed values are: RockyLinux8. Default: %(default)s
    """)

class PgVersionOption:
    choices = ['11', '12', '13', '14']
    default = '14'
    help = textwrap.dedent("""
        PostgreSQL or EPAS version. Allowed values are: 11, 12, 13 and 14.
        Default: %(default)s
    """)

class POTPgVersionOption:
    choices = ['14']
    default = '14'
    help = textwrap.dedent("""
        EPAS version. Allowed values are: 14.
        Default: %(default)s
    """)


class PgVersionOptionAzureDB:
    choices = ['11']
    default = '11'
    help = textwrap.dedent("""
        Azure Database for PostgreSQL version. Allowed values are: 11.
        Default: %(default)s
    """)


class EFMVersionOption:
    choices = ['3.10', '4.0', '4.1', '4.2', '4.3', '4.4', '4.5']
    default = '4.5'
    help = textwrap.dedent("""
        EDB Failover Manager version. Allowed values are: 3.10, 4.0, 4.1, 4.2, 4.3, 4.4 and 4.5.
        Default: %(default)s
    """)

class EFMVersionOptionVMWare:
    choices = ['3.10', '4.0', '4.1', '4.2', '4.3', '4.4', '4.5']
    default = '4.5'
    help = textwrap.dedent("""
        EDB Failover Manager version. Allowed values are: 3.10, 4.0, 4.1, 4.2, 4.3, 4.4 and 4.5.
        Default: %(default)s
    """)

class EFMVersionOptionVirtualBox:
    choices = ['3.10', '4.0', '4.1', '4.2', '4.3', '4.4', '4.5']
    default = '4.5'
    help = textwrap.dedent("""
        EDB Failover Manager version. Allowed values are: 3.10, 4.0, 4.1, 4.2, 4.3, 4.4 and 4.5.
        Default: %(default)s
    """)


class UseHostnameOption:
    choices = [True, False]
    default = True
    help = textwrap.dedent("""
        Use hostnames for connectivity between servers.
        Default: %(default)s
    """)


class PgTypeOption:
    choices = ['PG', 'EPAS']
    default = 'PG'
    help = textwrap.dedent("""
        Postgres engine type. Allowed values are: PG for PostgreSQL, EPAS for
        EDB Postgres Advanced Server. Default:
        %(default)s
    """)


class POTPgTypeOption:
    choices = ['EPAS']
    default = 'EPAS'
    help = textwrap.dedent("""
        Postgres engine type. Allowed values are: EPAS for
        EDB Postgres Advanced Server. Default:
        %(default)s
    """)


class PgTypeOptionRDS:
    choices = ['DBaaS']
    default = 'DBaaS'
    help = textwrap.dedent("""
        Postgres engine type. Allowed values are: DBaaS for AWS RDS.  Default:
        %(default)s
    """)


class PgTypeOptionAzureDB:
    choices = ['DBaaS']
    default = 'DBaaS'
    help = textwrap.dedent("""
        Postgres engine type. Allowed values are: DBaaS for Azure Database.
        Default: %(default)s
    """)

class PgTypeOptionGCloudSQL:
    choices = ['DBaaS']
    default = 'DBaaS'
    help = textwrap.dedent("""
        Postgres engine type. Allowed values are: DBaaS for Google Cloud SQL.
        Default: %(default)s
    """)

class MemSizeOptionsVMWare:
    choices = ['2048', '3072', '4096', '5120']
    default = '2048'
    help = textwrap.dedent("""
        Memory size options. Allowed values are: {choices} for VMWare.
        Default: %(default)s
    """)

class MemSizeOptionsVirtualBox:
    choices = ['2048', '3072', '4096', '5120']
    default = '2048'
    help = textwrap.dedent("""
        Memory size options. Allowed values are: {choices} for VirtualBox.
        Default: %(default)s
    """)

class CPUCountOptionsVMWare:
    choices = ['1', '2']
    default = '1'
    help = textwrap.dedent("""
        CPU Count options. Allowed values are: 1, 2 for VMWare.
        Default: %(default)s
    """)

class CPUCountOptionsVirtualBox:
    choices = ['1', '2']
    default = '1'
    help = textwrap.dedent("""
        CPU Count options. Allowed values are: 1, 2 for VirtualBox.
        Default: %(default)s
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


# HammerDB specific options
class ShirtSizeOption:
    choices = ['small', 'medium', 'large', 'xl']
    default = 'small'
    help = textwrap.dedent("""
        T-shirt sized system to provision.  Allowed values are small, medium,
        large, and xl.  Default : %(default)s
    """)


# Cloud specific options
class AWSRegionOption:
    choices = ['us-east-1', 'us-east-2', 'us-west-1', 'us-west-2','eu-west-1',
               'eu-west-2', 'eu-west-3']
    default = 'us-east-1'
    help = textwrap.dedent("""
        AWS region. Allowed values are us-east-1, us-east-2, us-west-1,
        us-west-2, eu-west-1, eu-west-2 and eu-west-3. Default: %(default)s
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


# Argcomplete completers
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
