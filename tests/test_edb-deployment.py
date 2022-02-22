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
    POT_R53_ACCESS_KEY,
    POT_R53_SECRET,
    POT_EMAIL_ID,
    POT_TPAEXEC_BIN,
    POT_TPAEXEC_SUBSCRIPTION_TOKEN,
    PROJECT_NAME,
    RA,
    SSH_PRIV_KEY,
    SSH_PUB_KEY,
    get_barmanserver,
    get_barmanservers,
    get_conf,
    get_pemserver,
    get_pg_nodes,
    get_pg_cluster_nodes,
    get_pgpool2,
    get_hosts,
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
            'state.json',
            'terraform_vars.json',
            'environments',
            'main.tf',
            'provider.tf',
            'tags.tf',
            'variables.tf',
        ]
        if RA.startswith('EDB-Always-On'):
            files += [
                'centos_%s_key.pem' % PROJECT_NAME,
                'centos_%s_key.pub' % PROJECT_NAME,
            ]
        else:
            files += [
                'ssh_priv_key',
                'ssh_pub_key',
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
        if RA.startswith('EDB-RA'):
            assert data['efm_version'] == EFM_VERSION
        if RA.startswith('EDB-Always-On'):
            assert data['tpa_subscription_token'] == POT_TPAEXEC_SUBSCRIPTION_TOKEN  # noqa
            assert data['tpaexec_bin'] == POT_TPAEXEC_BIN
            assert data['route53_access_key'] == POT_R53_ACCESS_KEY
            assert data['route53_secret'] == POT_R53_SECRET
            assert data['email_id'] == POT_EMAIL_ID

    def test_configure_terraform_vars(self, setup, configure):
        """
        Ensure the terraform_vars.json file has been populated with the right
        values.
        """
        data = load_terraform_vars(DEPLOY_DIR, CLOUD_VENDOR, PROJECT_NAME)

        assert data['pg_type'] == PG_TYPE
        assert data['pg_version'] == PG_VERSION
        if CLOUD_VENDOR in ['aws', 'aws-pot']:
            assert data['aws_region'] == CLOUD_REGION
        elif CLOUD_VENDOR == 'azure':
            assert data['azure_region'] == CLOUD_REGION
        elif CLOUD_VENDOR == 'gcloud':
            assert data['gcloud_region'] == CLOUD_REGION
        assert data['cluster_name'] == PROJECT_NAME
        if RA in ('EDB-RA-1', 'EDB-RA-2', 'EDB-RA-3'):
            assert data['dbt2_client']['count'] == 0
            assert data['dbt2_driver']['count'] == 0
            assert data['hammerdb'] is False
            assert data['hammerdb_server']['count'] == 0
            assert data['bdr_server']['count'] == 0
            assert data['bdr_witness_server']['count'] == 0
            assert data['barman'] is True
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
        if RA == 'EDB-Always-On-Silver':
            assert data['bdr_server']['count'] == 3
            assert data['bdr_witness_server']['count'] == 0
            assert data['pooler_server']['count'] == 2
            assert data['barman_server']['count'] == 1
            assert data['postgres_server']['count'] == 0
        elif RA == 'EDB-Always-On-Platinum':
            assert data['bdr_server']['count'] == 6
            assert data['bdr_witness_server']['count'] == 1
            assert data['pooler_server']['count'] == 4
            assert data['barman_server']['count'] == 2
            assert data['postgres_server']['count'] == 0

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
        elif RA.startswith('EDB-Always-On'):
            assert len(children.keys()) == 4

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
        elif RA.startswith('EDB-Always-On'):
            assert 'pgbouncer' in children

        # Test the number of machines
        # One PEM server
        assert len(children['pemserver']['hosts'].keys()) == 1
        # One barman server
        if RA == 'EDB-Always-On-Platinum':
            assert len(children['barmanserver']['hosts'].keys()) == 2
        else:
            assert len(children['barmanserver']['hosts'].keys()) == 1

        # One primary server for EDB-RA-*, multiple primaires for BDR arch.
        if RA == 'EDB-Always-On-Platinum':
            assert len(children['primary']['hosts'].keys()) == 7
        elif RA == 'EDB-Always-On-Silver':
            assert len(children['primary']['hosts'].keys()) == 3
        else:
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
        groups = ['primary', 'pemserver', 'barmanserver']
        if RA in ('EDB-RA-2', 'EDB-RA-3'):
            groups.append('standby')
        if RA == 'EDB-RA-3':
            groups.append('pgpool2')
        if RA.startswith('EDB-Always-On'):
            groups.append('pgbouncer')

        for group in groups:
            for host in get_hosts(group):
                # Execute the hostname command on the remote host
                assert host.run("hostname").rc == 0, \
                    "Cannot connect to %s with SSH" % host

    def test_deploy_primary(self, setup, configure, provision, deploy):
        """
        Checking Postgres instance on the primary nodes
        """
        conf = get_conf()[PG_TYPE]

        service_name = conf['service_name']
        port = conf['port']
        if RA.startswith('EDB-Always-On'):
            # unix_socket_directories is configured to the default value when
            # Postgres is deployed by TPAexec.
            unix_socket = "/tmp/.s.PGSQL.5444"
        else:
            unix_socket = conf['unix_socket']
        unix_socket_dir = os.path.dirname(unix_socket)
        user = conf['user']

        for primary in get_hosts('primary'):
            with primary.sudo():
                assert primary.service(service_name).is_running, \
                    "Service %s not running on %s" % (service_name, primary.check_output('hostname -s'))  # noqa
                assert primary.service(service_name).is_enabled, \
                    "Service %s not enabled on %s" % (service_name, primary.check_output('hostname -s'))  # noqa
                assert primary.socket('tcp://0.0.0.0:%s' % port).is_listening, \
                    "Postgres/EPAS not listening on 0.0.0.0:%s on %s" % (port, primary.check_output('hostname -s'))  # noqa
                assert primary.socket('unix://%s' % unix_socket).is_listening, \
                    "Postgres/EPAS not listening on %s on %s" % (unix_socket, primary.check_output('hostname -s'))  # noqa

            with primary.sudo(user):
                assert primary.check_output(
                    "psql -tA -h %s -p %s -d postgres -c 'SELECT pg_is_in_recovery()'"  # noqa
                    % (unix_socket_dir, port)
                ) == 'f', \
                    "Postgres/EPAS instance does not look to accept writes on %s" % primary.check_output('hostname -s')  # noqa

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
        if RA.startswith('EDB-Always-On'):
            for node in get_hosts('pgbouncer'):
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
        if RA.startswith('EDB-Always-On'):
            # unix_socket_directories is configured to the default value when
            # Postgres is deployed by TPAexec.
            unix_socket = "/tmp/.s.PGSQL.5444"
        else:
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
        if not RA.startswith('EDB-RA'):
            pytest.skip()

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
                    "Postgres/EPAS not listening on 0.0.0.0:%s on %s" % (port, host)  # noqa
                assert standby.socket('unix://%s' % unix_socket).is_listening, \
                    "Postgres/EPAS not listening on %s on %s" % (unix_socket, host)  # noqa

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
                    "Node type %s differs from %s on %s" % (node_status['type'].lower(), group_name, host)  # noqa
                assert node_status['db'] == 'UP', \
                    "Node status %s is not UP on %s" % (node_status['db'], host)  # noqa

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
                assert pgpool2.socket('tcp://0.0.0.0:%s' % port).is_listening,\
                    "pgpool2 not listening on 0.0.0.0:%s on %s" % (port, host)

    def test_bdr_deploy_barmanserver(self, setup, configure, provision,
                                     deploy):
        """
        Testing barman deployment in BDR environment: we just have to execute
        the barman check command for each Postgres node that are supposed to be
        backuped. If barman check does not return an error, everything is fine.
        """
        if not RA.startswith('EDB-Always-On'):
            pytest.skip()

        # List of BDR lead master nodes
        backuped_servers = ['epas1', 'epas4']

        i = 0
        for barmanserver in get_barmanservers():
            name = backuped_servers[i]
            i += 1
            with barmanserver.sudo('barman'):
                # Rexecute barman cron just to be sure the wal receiver is
                # running before checking because we don't want to wait until
                # it's executed automatically.
                barmanserver.run("barman cron")
                assert barmanserver.run("barman check %s" % name).succeeded, \
                    "barman check failed for %s" % name

    def test_bdr_harp_proxy(self, setup, configure, provision, deploy):
        """
        Testing harp-proxy deployment in BDR environment.
        """
        if not RA.startswith('EDB-Always-On'):
            pytest.skip()

        for host in get_hosts('pgbouncer'):
            with host.sudo():
                assert host.service('harp-proxy').is_running, \
                    "Service harp-proxy not running on %s" % host
                assert host.service('harp-proxy').is_enabled, \
                    "Service harp-proxy not enabled on %s" % host
                hostname_ip = host.check_output('hostname -i')
                assert host.socket('tcp://%s:6432' % hostname_ip).is_listening, \
                    "pgbouncer not listening on %s:6432 on %s" % (hostname_ip, host)  # noqa

    def test_bdr_harp_leader(self, setup, configure, provision, deploy):
        """
        Testing Harp leader nodes.
        """
        if not RA.startswith('EDB-Always-On'):
            pytest.skip()

        locations = ['BDRDC1', 'BDRDC2']
        lead_masters = ['epas1', 'epas4']

        i = 0
        for host in get_hosts('primary'):
            if host.check_output('hostname -s') not in lead_masters:
                # Execute this test only once per location
                continue

            location = locations[i]
            cmd = host.run("harpctl get leader %s -o json" % location)
            assert cmd.succeeded, \
                "Cannot execute the harpctl get leader command"
            json_output = json.loads(cmd.stdout)
            assert json_output['name'] == lead_masters[i], \
                "Harp leader configured to %s, must be %s" % (json_output['name'], lead_masters[i])  # noqa
            i += 1

    def test_bdr_pgbouncer_connection(self, setup, configure, provision,
                                      deploy):
        """
        Testing pgbouncer connection
        """
        if not RA.startswith('EDB-Always-On'):
            pytest.skip()

        conf = get_conf()[PG_TYPE]
        pg_user = conf['user']

        lead_masters = ['epas1', 'epas4']
        poolers = ['pgbouncer1', 'pgbouncer3']

        i = 0
        for host in get_hosts('primary'):
            if host.check_output('hostname -s') not in lead_masters:
                # Execute this test only once per location
                continue

            with host.sudo(pg_user):
                assert host.check_output(
                    "psql -tA -h %s -p 6432 -d edb -c 'SELECT 1'"
                    % poolers[i]
                ) == '1', \
                    "Pgbouncer connection does not work on %s" % poolers[i]

                assert host.check_output(
                    "psql -tA -h %s -p 6432 -d edb -c 'SELECT node_name FROM bdr.local_node_info()'"  # noqa
                    % poolers[i]
                ) == lead_masters[i], \
                    "Pgbouncer not connect to the right lead master node on %s" % poolers[i]  # noqa
            i += 1
