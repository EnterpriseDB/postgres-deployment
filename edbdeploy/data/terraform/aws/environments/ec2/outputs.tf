resource "local_file" "AnsibleYamlInventory" {
  filename = "${abspath(path.root)}/${var.ansible_inventory_yaml_filename}"
  content  = <<EOT
---
all:
  children:
%{if var.pem_server["count"] > 0~}
    pemserver:
      hosts:
%{if var.bdr_server["count"] > 0~}
        pemserver1:
%{else~}
        pemserver1.${var.cluster_name}.internal:
%{endif~}
          ansible_host: ${aws_instance.pem_server[0].public_ip}
          private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{for barman_count in range(var.barman_server["count"])~}
%{if barman_count == 0~}
    barmanserver:
      hosts:
%{endif~}
%{if var.bdr_server["count"] > 0~}
        barmandc${barman_count + 1}:
%{else~}
        barmanserver${barman_count + 1}.${var.cluster_name}.internal:
%{endif~}
          ansible_host: ${aws_instance.barman_server[barman_count].public_ip}
          private_ip: ${aws_instance.barman_server[barman_count].private_ip}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{endfor~}
%{if var.dbt2_client["count"] > 0~}
    dbt2_client:
      hosts:
%{for dbt2_client_count in range(var.dbt2_client["count"])~}
        dbt2_client${dbt2_client_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${aws_instance.dbt2_client[dbt2_client_count].public_ip}
          private_ip: ${aws_instance.dbt2_client[dbt2_client_count].private_ip}
%{endfor~}
%{endif~}
%{if var.dbt2_driver["count"] > 0~}
    dbt2_driver:
      hosts:
%{for dbt2_driver_count in range(var.dbt2_driver["count"])~}
        dbt2_driver${dbt2_driver_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${aws_instance.dbt2_driver[dbt2_driver_count].public_ip}
          private_ip: ${aws_instance.dbt2_driver[dbt2_driver_count].private_ip}
%{endfor~}
%{endif~}
%{if var.hammerdb_server["count"] > 0~}
    hammerdbserver:
      hosts:
        hammerdbserver1.${var.cluster_name}.internal:
          ansible_host: ${aws_instance.hammerdb_server[0].public_ip}
          private_ip: ${aws_instance.hammerdb_server[0].private_ip}
%{endif~}
%{for postgres_count in range(var.postgres_server["count"])~}
%{if postgres_count == 0~}
    primary:
      hosts:
%{endif~}
%{if postgres_count == 1~}
    standby:
      hosts:
%{endif~}
%{if var.pg_type == "EPAS"~}
        epas${postgres_count + 1}.${var.cluster_name}.internal:
%{else~}
        pgsql${postgres_count + 1}.${var.cluster_name}.internal:
%{endif~}
          ansible_host: ${aws_instance.postgres_server[postgres_count].public_ip}
          private_ip: ${aws_instance.postgres_server[postgres_count].private_ip}
%{if var.barman == true~}
          barman: true
          barman_server_private_ip: ${aws_instance.barman_server[0].private_ip}
          barman_backup_method: postgres
%{endif~}
%{if var.dbt2 == true~}
          dbt2: true
%{for dbt2_client_count in range(var.dbt2_client["count"])~}
          dbt2_client_private_ip${dbt2_client_count + 1}: ${aws_instance.dbt2_client[dbt2_client_count].private_ip}
%{endfor~}
%{endif~}
%{if var.hammerdb == true~}
          hammerdb: true
          hammerdb_server_private_ip: ${aws_instance.hammerdb_server[0].private_ip}
%{endif~}
%{if var.pooler_local == true && var.pooler_type == "pgbouncer"~}
          pgbouncer: true
%{endif~}
%{if postgres_count > 0~}
%{if postgres_count == 1~}
          replication_type: ${var.replication_type}
%{else~}
          replication_type: asynchronous
%{endif~}
          upstream_node_private_ip: ${aws_instance.postgres_server[0].private_ip}
%{endif~}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{endfor~}
%{for bdr_count in range(var.bdr_server["count"])~}
%{if bdr_count == 0~}
    primary:
      hosts:
%{endif~}
%{if var.pg_type == "EPAS"~}
        epas${bdr_count + 1}:
%{else~}
        pgsql${bdr_count + 1}:
%{endif~}
          ansible_host: ${aws_instance.bdr_server[bdr_count].public_ip}
          private_ip: ${aws_instance.bdr_server[bdr_count].private_ip}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{endfor~}
%{for bdr_witness_count in range(var.bdr_witness_server["count"])~}
%{if var.pg_type == "EPAS"~}
        epas${var.bdr_server["count"] + bdr_witness_count + 1}:
%{else~}
        pgsql${var.bdr_server["count"] + bdr_witness_count + 1}:
%{endif~}
          ansible_host: ${aws_instance.bdr_witness_server[bdr_witness_count].public_ip}
          private_ip: ${aws_instance.bdr_witness_server[bdr_witness_count].private_ip}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{endfor~}
%{for pooler_count in range(var.pooler_server["count"])~}
%{if pooler_count == 0~}
%{if var.pooler_type == "pgpool2"~}
    pgpool2:
%{endif~}
%{if var.pooler_type == "pgbouncer"~}
    pgbouncer:
%{endif~}
      hosts:
%{endif~}
%{if var.bdr_server["count"] > 0~}
        pgbouncer${pooler_count + 1}:
%{else~}
        ${var.pooler_type}${pooler_count + 1}.${var.cluster_name}.internal:
%{endif~}
          ansible_host: ${aws_instance.pooler_server[pooler_count].public_ip}
          private_ip: ${aws_instance.pooler_server[pooler_count].private_ip}
%{if var.postgres_server["count"] > 0~}
          primary_private_ip: ${aws_instance.postgres_server[0].private_ip}
%{endif~}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{endfor~}
EOT
}

resource "local_file" "host_script" {
  filename = "${abspath(path.root)}/${var.add_hosts_filename}"
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{for count in range(var.postgres_server["count"])~}
ssh-keyscan -H ${aws_instance.postgres_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.postgres_server[count].public_dns}
%{endfor~}
%{if var.pem_server["count"] > 0~}
ssh-keyscan -H ${aws_instance.pem_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keyscan -H ${aws_instance.pem_server[0].public_ip} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pem_server[0].public_dns}
%{endif~}
%{for barman_count in range(var.barman_server["count"])~}
ssh-keyscan -H ${aws_instance.barman_server[barman_count].public_ip} >> ~/.ssh/known_hosts
ssh-keyscan -H ${aws_instance.barman_server[barman_count].public_ip} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.barman_server[barman_count].public_dns}
%{endfor~}
%{for count in range(var.pooler_server["count"])~}
ssh-keyscan -H ${aws_instance.pooler_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keyscan -H ${aws_instance.pooler_server[count].public_ip} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pooler_server[count].public_dns}
%{endfor~}
%{for count in range(var.bdr_server["count"])~}
ssh-keyscan -H ${aws_instance.bdr_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keyscan -H ${aws_instance.bdr_server[count].public_ip} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.bdr_server[count].public_dns}
%{endfor~}
%{for count in range(var.bdr_witness_server["count"])~}
ssh-keyscan -H ${aws_instance.bdr_witness_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keyscan -H ${aws_instance.bdr_witness_server[count].public_ip} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.bdr_witness_server[count].public_dns}
%{endfor~}
    EOT
}

resource "local_file" "TPAexecYamlConfig" {
  filename = "${abspath(path.root)}/${var.tpaexec_config_yaml_filename}"
  content  = <<EOT
%{if var.bdr_server["count"] > 0~}
---
architecture: BDR-Always-ON
cluster_name: ${var.cluster_name}
cluster_tags: {}

cluster_vars:
  bdr_database: edb
  bdr_node_group: bdrgroup
  extra_postgres_extensions:
  - pglogical
  failover_manager: harp
  harp_consensus_protocol: etcd
  postgres_data_dir: /pgdata/pg_data
  postgres_initdb_opts:
  - --waldir=/pgwal/pg_wal
  postgres_coredump_filter: '0xff'
  postgres_version: '13'
  postgresql_flavour: epas
  postgres_user: enterprisedb
  postgres_group: enterprisedb
  postgres_conf_settings:
     shared_preload_libraries: "'dbms_pipe, edb_gen, dbms_aq, edb_wait_states, sql-profiler, index_advisor, pg_stat_statements, pglogical, bdr'"
  pg_systemd_service_path: '/etc/systemd/system/postgres.service'
  pg_systemd_alias: 'edb-as-13.service'
  preferred_python_version: python3
  repmgr_failover: manual
  tpa_2q_repositories:
  - products/bdr_enterprise_3_7-epas/release
  - products/pglogical3_7/release
  yum_repository_list:
  - EDB
  - EPEL
  use_volatile_subscriptions: false
  publications:
  - type: bdr
    database: edb
    replication_sets:
    - name: bdrgroup
      autoadd_tables: false
      replicate_delete: false
      replicate_insert: false
      replicate_truncate: false
      replicate_update: false
    - name: bdrdatagroup
      autoadd_tables: true
      replicate_delete: true
      replicate_insert: true
      replicate_truncate: true
      replicate_update: true
  bdr_extensions:
    - btree_gist
    - pglogical
    - bdr
  etcd_packages:
    Debian: []
    RedHat: []


ssh_key_file: ${var.ssh_priv_key}

locations:
- Name: BDRDC1
- Name: BDRDC2
- Name: BDRDC3

instance_defaults:
  platform: bare
  vars:
    ansible_user: ${var.ssh_user}

instances:
%{for bdr_count in range(var.bdr_server["count"])~}
%{if var.pg_type == "EPAS"~}
- Name: epas${bdr_count + 1}
%{else~}
- Name: pgsql${bdr_count + 1}
%{endif~}
%{if bdr_count < 3~}
  location: BDRDC1
%{else~}
  location: BDRDC2
%{endif~}
  node: ${bdr_count + 1}
  public_ip: ${aws_instance.bdr_server[bdr_count].public_ip}
  private_ip: ${aws_instance.bdr_server[bdr_count].private_ip}
%{if bdr_count == 0~}
  backup: barmandc1
%{endif~}
%{if bdr_count == 3~}
  backup: barmandc2
%{endif~}
  role:
  - primary
  - bdr
%{if bdr_count == 2 || bdr_count == 5~}
%{if var.bdr_server["count"] > 3~}
  - readonly
%{if bdr_count < 3~}
%{if var.pg_type == "EPAS"~}
  - upstream: epas1
%{else~}
  - upstream: pgsql1
%{endif~}
%{else~}
%{if var.pg_type == "EPAS"~}
  - upstream: epas4
%{else~}
  - upstream: pgsql4
%{endif~}
%{endif~}
%{endif~}
%{endif~}
  vars:
    subscriptions:
    - database: edb
      type: bdr
      replication_sets:
      - bdrgroup
      - bdrdatagroup
%{endfor~}
%{for witness_count in range(var.bdr_witness_server["count"])~}
%{if var.pg_type == "EPAS"~}
- Name: epas${var.bdr_server["count"] + witness_count + 1}
%{else~}
- Name: pgsql${var.bdr_server["count"] + witness_count + 1}
%{endif~}
  location: BDRDC3
  node: ${var.bdr_server["count"] + witness_count + 1}
  public_ip: ${aws_instance.bdr_witness_server[witness_count].public_ip}
  private_ip: ${aws_instance.bdr_witness_server[witness_count].private_ip}
  role:
  - primary
  - bdr
  vars:
    subscriptions:
    - database: edb
      type: bdr
      replication_sets:
      - bdrgroup
%{endfor~}
%{for pooler_count in range(var.pooler_server["count"])~}
- Name: pgbouncer${pooler_count + 1}
%{if pooler_count < 3~}
  location: BDRDC1
%{else~}
  location: BDRDC2
%{endif~}
  node: ${var.bdr_server["count"] + var.bdr_witness_server["count"] + pooler_count + 1}
  public_ip:  ${aws_instance.pooler_server[pooler_count].public_ip}
  private_ip: ${aws_instance.pooler_server[pooler_count].private_ip}
  role:
  - pgbouncer
  - harp-proxy
  - etcd
%{endfor~}
%{for barman_count in range(var.barman_server["count"])~}
- Name: barmandc${barman_count + 1}
%{if barman_count == 0~}
  location: BDRDC1
%{else~}
  location: BDRDC2
%{endif~}
  node: ${var.bdr_server["count"] + var.bdr_witness_server["count"] + var.pooler_server["count"] + barman_count + 1}
  public_ip: ${aws_instance.barman_server[barman_count].public_ip}
  private_ip: ${aws_instance.barman_server[barman_count].private_ip}
  role:
  - barman
  - etcd
%{endfor~}
%{if var.pem_server["count"] > 0~}
- Name: pemserver1
  node: ${var.bdr_server["count"] + var.bdr_witness_server["count"] + var.pooler_server["count"] + var.barman_server["count"] + 1}
  location: BDRDC3
  public_ip: ${aws_instance.pem_server[0].public_ip}
  private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{endif~}
EOT
}

resource "local_file" "ssh_config" {
  filename        = "${abspath(path.root)}/ssh_config"
  file_permission = "0600"
  content         = <<-EOT

Host *
    Port 22
    IdentitiesOnly yes
    IdentityFile "${basename(var.ssh_priv_key)}"
    UserKnownHostsFile known_hosts tpa_known_hosts
    ServerAliveInterval 60

%{for count in range(var.postgres_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${count + 1}
%{else~}
Host pgsql${count + 1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${aws_instance.postgres_server[count].public_ip}
%{endfor~}
%{for count in range(var.bdr_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${count + 1}
%{else~}
Host pgsql${count + 1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${aws_instance.bdr_server[count].public_ip}
%{endfor~}
%{if var.pem_server["count"] > 0~}
Host pemserver1
    User ${var.ssh_user}
    Hostname ${aws_instance.pem_server[0].public_ip}
%{endif~}
%{for count in range(var.barman_server["count"])~}
%{if var.bdr_server["count"] > 0~}
Host barmandc${count + 1}:
%{else~}
Host barmanserver${count + 1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${aws_instance.barman_server[0].public_ip}
%{endfor~}
%{for count in range(var.dbt2_client["count"])~}
Host dbt2_client${count + 1}
    User ${var.ssh_user}
    Hostname ${aws_instance.dbt2_client[count].public_ip}
%{endfor~}
%{for count in range(var.dbt2_driver["count"])~}
Host dbt2_driver${count + 1}
    User ${var.ssh_user}
    Hostname ${aws_instance.dbt2_driver[count].public_ip}
%{endfor~}
%{for count in range(var.hammerdb_server["count"])~}
Host hammerdbserver${count + 1}
    User ${var.ssh_user}
    Hostname ${aws_instance.hammerdb_server[count].public_ip}
%{endfor~}
%{for count in range(var.bdr_witness_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${var.bdr_server["count"] + count + 1}
%{else~}
Host pgsql${var.bdr_server["count"] + count + 1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${aws_instance.bdr_witness_server[count].public_ip}
%{endfor~}
%{for count in range(var.pooler_server["count"])~}
%{if var.pooler_type == "pgpool2"~}
Host pgpool2${count + 1}
%{else~}
Host pgbouncer${count + 1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${aws_instance.pooler_server[count].public_ip}
%{endfor~}
    EOT
}
