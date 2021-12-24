import json
import os
import pytest

from conftest import (
    CLOUD_REGION,
    CLOUD_VENDOR,
    DEPLOY_DIR,
    EDB_CREDENTIALS,
    EFM_VERSION,
    PG_TYPE,
    PG_VERSION,
    PROJECT_NAME,
    RA,
    SSH_PRIV_KEY,
    SSH_PUB_KEY,
    get_barmanserver,
    get_conf,
    get_pemserver,
    get_pg_nodes,
    get_pg_cluster_nodes,
    get_pgpool2,
    get_hosts,
    get_primary,
    get_standbys,
    load_ansible_vars,
    load_inventory,
    load_terraform_vars,
)

class TestEDBDeployment:

    def test_configure_project_dir(self, setup, configure):
        """
        Ensure project folder exists
        """
        project_dir = os.path.join(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)
        assert os.path.exists(project_dir), \
            "Directory %s does not exist" % project_dir

    def test_configure_project_structure(self, setup, configure):
        """
        Ensure project structure is right
        """
        files = [
            'ansible_vars.json',
            'playbook.yml',
            'ssh_priv_key',
            'state.json',
            'terraform_vars.json',
            'environments',
            'main.tf',
            'provider.tf',
            'ssh_pub_key',
            'tags.tf',
            'variables.tf',
        ]
        for file in files:
            file_path = os.path.join(
                DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME, file
            )
            assert os.path.exists(file_path), \
                "File %s does not exist" % file_path

    def test_configure_ansible_vars(self, setup, configure):
        """
        Ensure the ansible_vars.json file has been populated with the right
        values.
        """
        data = load_ansible_vars(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)
        (repo_username, repo_password) = EDB_CREDENTIALS.split(':')

        assert data['reference_architecture'] == RA
        assert data['repo_username'] == repo_username
        assert data['repo_password'] == repo_password
        assert data['cluster_name'] == PROJECT_NAME
        assert data['pg_type'] == PG_TYPE
        assert data['pg_version'] == PG_VERSION
        assert data['efm_version'] == EFM_VERSION

    def test_configure_terraform_vars(self, setup, configure):
        """
        Ensure the terraform_vars.json file has been populated with the right
        values.
        """
        data = load_terraform_vars(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)

        assert data['pg_type'] == PG_TYPE
        assert data['pg_version'] == PG_VERSION
        if CLOUD_VENDOR == 'aws':
            assert data['aws_region'] == CLOUD_REGION
        elif CLOUD_VENDOR == 'azure':
            assert data['azure_region'] == CLOUD_REGION
        elif CLOUD_VENDOR == 'gcloud':
            assert data['gcloud_region'] == CLOUD_REGION
        assert data['cluster_name'] == PROJECT_NAME
        if RA in ('EDB-RA-1', 'EDB-RA-2', 'EDB-RA-3'):
            assert data['dbt2_client']['count'] == 0
            assert data['dbt2_driver']['count'] == 0
            assert data['hammerdb'] == False
            assert data['hammerdb_server']['count'] == 0
            assert data['bdr_server']['count'] == 0
            assert data['bdr_witness_server']['count'] == 0
            assert data['barman'] == True
            assert data['barman_server']['count'] == 1
            assert data['pem_server']['count'] == 1
            if RA == 'EDB-RA-1':
                assert data['postgres_server']['count'] == 1
            else:
                assert data['postgres_server']['count'] == 3
            if RA == 'EDB-RA-3':
                assert data['pooler_server']['count'] == 3
            else:
                assert data['pooler_server']['count'] == 0

    def test_configure_ssh(self, setup, configure):
        """
        Check SSH keys
        """
        ansible_data = load_ansible_vars(
            DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME
        )
        terraform_data = load_terraform_vars(
            DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME
        )

        assert os.path.exists(ansible_data['ssh_priv_key']), \
            "The Ansible SSH private key %s does not exist" % ansible_data['ssh_priv_key']  # noqa

        with open(ansible_data['ssh_priv_key'], 'r') as f:
            with open(SSH_PRIV_KEY, 'r') as g:
                assert f.read() == g.read(), \
                    "SSH private keys do not match"

        assert os.path.exists(terraform_data['ssh_priv_key']), \
            "The Terraform SSH private key %s does not exist" % terraform_data['ssh_priv_key']  # noqa
        assert os.path.exists(terraform_data['ssh_pub_key']), \
            "The Terraform SSH public key %s does not exist" % terraform_data['ssh_pub_key']  # noqa

        with open(terraform_data['ssh_priv_key'], 'r') as f:
            with open(SSH_PRIV_KEY, 'r') as g:
                assert f.read() == g.read(), \
                    "SSH private keys do not match"
        with open(terraform_data['ssh_pub_key'], 'r') as f:
            with open(SSH_PUB_KEY, 'r') as g:
                assert f.read() == g.read(), \
                    "SSH public keys do not match"

    def test_provision_state_json(self, setup, configure, provision):
        """
        Testing that the state.json file is created and contains the right
        informations.
        """
        state_path = os.path.join(
            DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME, 'state.json'
        )
        assert os.path.exists(state_path), \
            "The file %s does not exist" % state_path
        with open(state_path, 'r') as f:
            state_data = json.loads(f.read())
        assert state_data['terraform'] == "PROVISIONED"

    def test_provision_inventory_yml(self, setup, configure, provision):
        """
        Testing that the inventory.yml file is created and contains the right
        informations.
        """
        inventory_path = os.path.join(
            DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME, 'inventory.yml'
        )
        assert os.path.exists(inventory_path), \
            "The file %s does not exist" % inventory_path

        inventory_data = load_inventory(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)

        children = inventory_data['all']['children']

        if RA == 'EDB-RA-1':
            assert len(children.keys()) == 3
        elif RA == 'EDB-RA-2':
            assert len(children.keys()) == 4
        elif RA == 'EDB-RA-3':
            assert len(children.keys()) == 5

        assert 'primary' in children
        assert 'barmanserver' in children
        assert 'pemserver' in children
        if RA == 'EDB-RA-1':
            assert 'standby' not in children
            assert 'pgpool2' not in children
        elif RA == 'EDB-RA-2':
            assert 'standby' in children
            assert 'pgpool2' not in children
        elif RA == 'EDB-RA-3':
            assert 'standby' in children
            assert 'pgpool2' in children

        # Test the number of machines
        # One PEM server
        assert len(children['pemserver']['hosts'].keys()) == 1
        # One barman server
        assert len(children['barmanserver']['hosts'].keys()) == 1
        # One primary server
        assert len(children['primary']['hosts'].keys()) == 1
        if RA in ('EDB-RA-2', 'EDB-RA-3'):
            # Two standby servers
            assert len(children['standby']['hosts'].keys()) == 2
        if RA == 'EDB-RA-3':
            assert len(children['pgpool2']['hosts'].keys()) == 3

    def test_provision_ssh_machines(self, setup, configure, provision):
        """
        Testing SSH connections to the machines
        """
        inventory_data = load_inventory(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)
        children = inventory_data['all']['children']

        # Read terraform variables
        terraform_data = load_terraform_vars(
            DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME
        )
        ssh_user = terraform_data['ssh_user']

        groups = ['primary', 'pemserver', 'barmanserver']
        if RA in ('EDB-RA-2', 'EDB-RA-3'):
            groups.append('standby')
        if RA == 'EDB-RA-3':
            groups.append('pgpool2')

        for group in groups:
            for host in get_hosts(group):
                # Execute the hostname command on the remote host
                assert host.run("hostname").rc == 0, \
                    "Cannot connect to %s with SSH" % host

    def test_deploy_primary(self, setup, configure, provision, deploy):
        """
        Checking Postgres instance on the primary node
        """
        primary = get_primary()
        conf = get_conf()[PG_TYPE]

        service_name = conf['service_name']
        port = conf['port']
        unix_socket = conf['unix_socket']
        unix_socket_dir = os.path.dirname(unix_socket)
        user = conf['user']

        with primary.sudo():
            assert primary.service(service_name).is_running, \
                "Service %s not running" % service_name
            assert primary.service(service_name).is_enabled, \
                "Service %s not enabled" % service_name
            assert primary.socket('tcp://0.0.0.0:%s' % port).is_listening, \
                "Postgres/EPAS not listening on 0.0.0.0:%s" % port
            assert primary.socket('unix://%s' % unix_socket).is_listening, \
                "Postgres/EPAS not listening on %s" % unix_socket

        with primary.sudo(user):
            assert primary.check_output(
                "psql -tA -h %s -p %s -d postgres -c 'SELECT pg_is_in_recovery()'"  # noqa
                % (unix_socket_dir, port)
            ) == 'f', \
                "Postgres/EPAS instance does not look to accept writes"

    def test_deploy_pemagent(self, setup, configure, provision, deploy):
        """
        Testing PEM agent on the primary, standbys and PEM server
        """
        for (group, node) in get_pg_nodes():
            assert node.service('pemagent').is_running, \
                "Service pemagent not running on %s" % node.check_output('hostname -s')  # noqa
            assert node.service('pemagent').is_enabled, \
                "Service pemagent not enabled on %s" % node.check_output('hostname -s')  # noqa
            if group not in ('pemserver'):
                assert node.file('/usr/edb/pem/agent/etc/.agentregistered').exists, \
                    "Agent not registered on %s" % node.check_output('hostname -s')  # noqa

    def test_deploy_pemserver(self, setup, configure, provision, deploy):
        """
        Testing PEM server deployment: httpd is running and enabled,
        Postgres service is running and enabled, Postgres instance is running
        and accepting writes.
        """
        conf = get_conf()[PG_TYPE]

        service_name = conf['service_name']
        port = conf['port']
        unix_socket = conf['unix_socket']
        unix_socket_dir = os.path.dirname(unix_socket)
        user = conf['user']

        pemserver = get_pemserver()
        with pemserver.sudo():
            assert pemserver.service('httpd').is_running, \
                "Service httpd not running on %s" % pemserver.check_output('hostname -s')  # noqa
            assert pemserver.service('httpd').is_enabled, \
                "Service httpd not enabled on %s" % pemserver.check_output('hostname -s')  # noqa
            assert pemserver.service(service_name).is_running, \
                "Service %s not running on %s" % (service_name, pemserver.check_output('hostname -s'))  # noqa
            assert pemserver.service(service_name).is_enabled, \
                "Service %s not enabled on %s" % (service_name, pemserver.check_output('hostname -s'))  # noqa
            assert pemserver.socket('tcp://0.0.0.0:%s' % port).is_listening, \
                "Postgres/EPAS not listening on 0.0.0.0:%s on %s" % (port, pemserver.check_output('hostname -s'))  # noqa
            assert pemserver.socket('unix://%s' % unix_socket).is_listening, \
                "Postgres/EPAS not listening on %s on %s" % (unix_socket, pemserver.check_output('hostname -s'))  # noqa

        with pemserver.sudo(user):
            assert pemserver.check_output(
                "psql -tA -h %s -p %s -d postgres -c 'SELECT pg_is_in_recovery()'"  # noqa
                % (unix_socket_dir, port)
            ) == 'f', \
                "Postgres/EPAS instance does not look to accept writes on %s" % pemserver.check_output('hostname -s')  # noqa

    def test_deploy_barmanserver(self, setup, configure, provision, deploy):
        """
        Testing barman deployment: we just execute the barman check command for
        each Postgres node that are supposed to be backuped. If barman check
        does not return an error, everything is fine.
        """
        conf = get_conf()[PG_TYPE]
        barmanserver = get_barmanserver()

        barman_pg_name = conf['fqdn'] % '1'

        name = "%s-%s" % (barman_pg_name, conf['instance_name'])

        with barmanserver.sudo('barman'):
            # Rexecute barman cron just to be sure the wal receiver is
            # running before checking because we don't want to wait until
            # it's executed automatically.
            barmanserver.run("barman cron")

            assert barmanserver.run("barman check %s" % name).succeeded, \
                "barman check failed for %s" % name

    def test_deploy_standbys(self, setup, configure, provision, deploy):
        """
        Testing that each standby node is running a Postgres/EPAS instance
        configured in streaming replication.
        """
        if RA not in ('EDB-RA-2', 'EDB-RA-3'):
            pytest.skip()

        conf = get_conf()[PG_TYPE]

        service_name = conf['service_name']
        port = conf['port']
        unix_socket = conf['unix_socket']
        unix_socket_dir = os.path.dirname(unix_socket)
        user = conf['user']

        for standby in get_standbys():
            host = standby.check_output('hostname -s')

            with standby.sudo():
                assert standby.service(service_name).is_running, \
                    "Service %s not running on %s" % (service_name, host)
                assert standby.service(service_name).is_enabled, \
                    "Service %s not enabled on %s" % (service_name, host)
                assert standby.socket('tcp://0.0.0.0:%s' % port).is_listening, \
                    "Postgres/EPAS not listening on 0.0.0.0:%s on %s" % (port, host)
                assert standby.socket('unix://%s' % unix_socket).is_listening, \
                    "Postgres/EPAS not listening on %s on %s" % (unix_socket, host)

            with standby.sudo(user):
                assert standby.check_output(
                    "psql -tA -h %s -p %s -d postgres -c 'SELECT pg_is_in_recovery()'"  # noqa
                    % (unix_socket_dir, port)
                ) == 't', \
                    "Postgres/EPAS instance not in recovery mode on %s" % host
                assert standby.file('/pgdata/pg_data/standby.signal').exists, \
                    "The standby.signal file does not exist on %s" % host

    def test_deploy_efm(self, setup, configure, provision, deploy):
        """
        Testing that each Postgres/EPAS node that is part of the HA cluster
        is running EFM and the EFM's node-status-json command returns the right
        informations.
        """
        if RA not in ('EDB-RA-2', 'EDB-RA-3'):
            pytest.skip()

        efm_conf = get_conf()['EFM']

        service_name = efm_conf['service_name']
        cluster_name = efm_conf['cluster_name']
        efm_bin = efm_conf['bin']

        for (group_name, node) in get_pg_cluster_nodes():
            host = node.check_output('hostname -s')

            with node.sudo():
                assert node.service(service_name).is_running, \
                    "Service %s not running on %s" % (service_name, host)
                assert node.service(service_name).is_enabled, \
                    "Service %s not enabled on %s" % (service_name, host)

                node_status = json.loads(
                    node.check_output(
                        "%s node-status-json %s" % (efm_bin, cluster_name)
                    )
                )
                assert node_status['type'].lower() == group_name, \
                    "Node type %s differs from %s on %s" % (node_status['type'].lower(), group_name, host)
                assert node_status['db'] == 'UP', \
                    "Node status %s is not UP on %s" % (node_status['db'], host)

    def test_deploy_pgpool2(self, setup, configure, provision, deploy):
        if RA not in ('EDB-RA-3'):
            pytest.skip()

        pg_conf = get_conf()[PG_TYPE]

        service_name = pg_conf['pgpool2']['service_name']
        port = pg_conf['pgpool2']['port']

        for pgpool2 in get_pgpool2():
            host = pgpool2.check_output('hostname -s')

            with pgpool2.sudo():
                assert pgpool2.service(service_name).is_running, \
                    "Service %s not running on %s" % (service_name, host)
                assert pgpool2.service(service_name).is_enabled, \
                    "Service %s not enabled on %s" % (service_name, host)
                assert pgpool2.socket('tcp://0.0.0.0:%s' % port).is_listening, \
                    "pgpool2 not listening on 0.0.0.0:%s on %s" % (port, host)
