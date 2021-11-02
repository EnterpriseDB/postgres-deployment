import os
import json
import pytest
import testinfra
import yaml

from edbdeploy.cli import EDBDeploymentCLI

# Path to the folder containing data files needed for the tests like SSH keys
TEST_DATA_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), 'data'
)

# Global variables used for the tests
RA = os.getenv('EDB_DEPLOY_RA', 'EDB-RA-1')
PG_TYPE = os.getenv('EDB_DEPLOY_PG_TYPE', 'PG')
PG_VERSION = os.getenv('EDB_DEPLOY_PG_VERSION', '13')
CLOUD_VENDOR = os.getenv('EDB_DEPLOY_CLOUD_VENDOR', 'aws')
CLOUD_REGION = os.getenv('EDB_DEPLOY_CLOUD_REGION', 'us-east-2')
EDB_CREDENTIALS = os.getenv('EDB_DEPLOY_EDB_CREDENTIALS', 'user:password')
PROJECT_NAME = 'testproject'
SSH_PRIV_KEY = os.path.join(TEST_DATA_DIR, 'test_id_rsa')
SSH_PUB_KEY = os.path.join(TEST_DATA_DIR, 'test_id_rsa.pub')
SSH_CONFIG = os.path.join(TEST_DATA_DIR, 'ssh_config')
EFM_VERSION = os.getenv('EDB_DEPLOY_EFM_VERSION', '4.2')
DEPLOY_DIR = os.getenv(
    'EDB_DEPLOY_DIR', os.path.join(os.path.expanduser("~"), ".edb-deployment")
)
GCLOUD_CRED = os.getenv(
    'EDB_GOOGLE_ACCOUNTS_FILE', os.path.join(os.path.expanduser("~"), "accounts.json")
)
GCLOUD_PROJECT_ID = os.getenv(
    'EDB_GCLOUD_PROJECT_ID', 'project_id'
)


@pytest.fixture(scope="class")
def setup():
    c = EDBDeploymentCLI([
        CLOUD_VENDOR, 'setup'
    ])
    c.execute()
    yield


@pytest.fixture(scope="class")
def configure():
    options = [
        CLOUD_VENDOR, 'configure',
        '--reference-architecture=%s' % RA,
        '--edb-credentials=%s' % EDB_CREDENTIALS,
        '--pg-type=%s' % PG_TYPE,
        '--pg-version=%s' % PG_VERSION,
        '--ssh-private-key=%s' % SSH_PRIV_KEY,
        '--ssh-pub-key=%s' % SSH_PUB_KEY,
        '--efm-version=%s' % EFM_VERSION,
    ]
    if CLOUD_VENDOR == 'aws':
        options.append(
            '--aws-region=%s' % CLOUD_REGION
        )
    elif CLOUD_VENDOR == 'azure':
        options.append(
            '--azure-region=%s' % CLOUD_REGION
        )
    elif CLOUD_VENDOR == 'gcloud':
        options.append(
        '--gcloud-region=%s' % CLOUD_REGION
    )
        options.append(
        '--gcloud-project-id=%s' % GCLOUD_PROJECT_ID
    )
        options.append(
        '--gcloud-credentials=%s' % GCLOUD_CRED
    )
    options.append(
        PROJECT_NAME
    )

    c = EDBDeploymentCLI(options)
    c.execute()
    yield
    c = EDBDeploymentCLI([
        CLOUD_VENDOR, 'remove', PROJECT_NAME
    ])
    c.execute()


@pytest.fixture(scope="class")
def provision():
    c = EDBDeploymentCLI([
        CLOUD_VENDOR, 'provision', PROJECT_NAME
    ])
    c.execute()
    yield
    c = EDBDeploymentCLI([
        CLOUD_VENDOR, 'destroy', PROJECT_NAME
    ])
    c.execute()


@pytest.fixture(scope="class")
def deploy():
    c = EDBDeploymentCLI([
        CLOUD_VENDOR, 'deploy', PROJECT_NAME
    ])
    c.execute()
    yield


def load_inventory(deploy_dir, cloud_vendor, project_name):
    """
    Loading data from the inventory file
    """
    project_path = os.path.join(deploy_dir, cloud_vendor, project_name)
    # Read the inventory file
    inventory_path = os.path.join(project_path, 'inventory.yml')
    with open(inventory_path, 'r') as f:
        return yaml.load(f.read(), Loader=yaml.Loader)


def load_terraform_vars(deploy_dir, cloud_vendor, project_name):
    """
    Loading Terraform variables from the terraform_vars.json file
    """
    project_path = os.path.join(deploy_dir, cloud_vendor, project_name)
    with open(os.path.join(project_path, 'terraform_vars.json'), 'r') as f:
        return json.loads(f.read())


def load_ansible_vars(deploy_dir, cloud_vendor, project_name):
    """
    Loading Ansible variables from the ansible_vars.json file
    """
    project_path = os.path.join(deploy_dir, cloud_vendor, project_name)
    with open(os.path.join(project_path, 'ansible_vars.json'), 'r') as f:
        return json.loads(f.read())


def get_hosts(group_name):
    """
    Returns the list of testinfra host instances, based on Ansible group name
    """
    inventory_data = load_inventory(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)
    children = inventory_data['all']['children']

    if group_name not in children:
        return []

    # Read terraform variables
    terraform_data = load_terraform_vars(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)
    ssh_user = terraform_data['ssh_user']

    nodes = []
    for host, attrs in children[group_name]['hosts'].items():
        nodes.append(
            testinfra.get_host(
                'paramiko://%s@%s:22' % (ssh_user, attrs['ansible_host']),
                ssh_identity_file=SSH_PRIV_KEY,
                ssh_config=SSH_CONFIG,
            )
        )
    return nodes


def get_primary():
    return get_hosts('primary')[0]


def get_pemserver():
    return get_hosts('pemserver')[0]


def get_barmanserver():
    return get_hosts('barmanserver')[0]


def get_pg_nodes():
    for group in ('primary', 'standby', 'pemserver'):
        for host in get_hosts(group):
            yield (group, host)


def get_pg_cluster_nodes():
    for group in ('primary', 'standby'):
        for host in get_hosts(group):
            yield (group, host)


def get_standbys():
    return get_hosts('standby')


def get_pgpool2():
    return get_hosts('pgpool2')


def get_conf():
    return dict(
        EPAS=dict(
            service_name="edb-as-%s" % PG_VERSION,
            port=5444,
            unix_socket="/var/run/edb/as%s/.s.PGSQL.5444" % PG_VERSION,
            user="enterprisedb",
            instance_name="main",
            fqdn="epas%s."+PROJECT_NAME+".internal",
        ),
        PG=dict(
            service_name="postgresql-%s" % PG_VERSION,
            port=5432,
            unix_socket="/var/run/postgresql/.s.PGSQL.5432",
            user="postgres",
            instance_name="main",
            fqdn="pgsql%s."+PROJECT_NAME+".internal",
            pgpool2=dict(
                service_name="pgpool-II-%s" % PG_VERSION,
                port=9999,
                
            )
        ),
        EFM=dict(
            service_name="edb-main-4.2",
            bin="/usr/edb/efm-4.2/bin/efm",
            cluster_name="main",
        ),
    )
