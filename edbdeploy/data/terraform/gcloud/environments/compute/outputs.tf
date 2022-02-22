locals {
  server_count_map = {
    postgres_server = var.postgres_server
    bdr_server = var.bdr_server
    bdr_witness_server = var.bdr_witness_server
    pem_server = var.pem_server
    barman_server = var.barman_server
    pooler_server = var.pooler_server
    dbt2_client = var.dbt2_client
    dbt2_driver = var.dbt2_driver
    hammerdb_server = var.hammerdb_server
  }
  google_compute_map = {
    postgres_server = google_compute_instance.postgres_server
    bdr_server = google_compute_instance.bdr_server
    bdr_witness_server = google_compute_instance.bdr_witness_server
    pem_server = google_compute_instance.pem_server
    barman_server = google_compute_instance.barman_server
    pooler_server = google_compute_instance.pooler_server
    dbt2_client = google_compute_instance.dbt2_client
    dbt2_driver = google_compute_instance.dbt2_driver
    hammerdb_server = google_compute_instance.hammerdb_server
  }
}

resource "local_file" "host_script" {
  filename = "${abspath(path.root)}/${var.add_hosts_filename}"
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{for k in keys(local.server_count_map) ~}
%{for count in range(local.server_count_map[k]["count"])~}
ssh-keyscan -H ${local.google_compute_map[k][count].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keyscan -H ${local.google_compute_map[k][count].network_interface.0.access_config.0.nat_ip} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${local.google_compute_map[k][count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
%{endfor~}
    EOT
}

resource "local_file" "servers_yml" {
  filename        = "${abspath(path.root)}/servers.yml"
  file_permission = "0700"
  content         = <<-EOT
---
servers:
%{for k in keys(local.server_count_map) ~}
%{if local.server_count_map[k]["count"] > 0~}
  ${k}:
%{for count in range(local.server_count_map[k]["count"])~}
    - id: ${count + 1}
      public_ip: ${local.google_compute_map[k][count].network_interface.0.access_config.0.nat_ip}
      private_ip: ${local.google_compute_map[k][count].network_interface.0.network_ip}
%{endfor~}
%{endif~}
%{endfor~}
    EOT
}

resource "local_file" "ssh_config" {
  filename = "${abspath(path.root)}/ssh_config"
  file_permission = "0600"
  content  = <<-EOT

Host *
    Port 22
    IdentitiesOnly yes
    IdentityFile "${basename(var.ssh_priv_key)}"
    UserKnownHostsFile known_hosts tpa_known_hosts
    ServerAliveInterval 60

%{for count in range(var.postgres_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${count+1}
%{else~}
Host pgsql${count+1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${google_compute_instance.postgres_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
%{for count in range(var.bdr_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${count+1}
%{else~}
Host pgsql${count+1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${google_compute_instance.bdr_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
%{for count in range(var.bdr_witness_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${count+1}
%{else~}
Host pgsql${count+1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${google_compute_instance.bdr_witness_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
%{if var.pem_server["count"] > 0~}
Host pemserver1
    User ${var.ssh_user}
    Hostname ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
%{endif~}
%{for count in range(var.barman_server["count"])~}
Host barmanserver${count+1}
    User ${var.ssh_user}
    Hostname ${google_compute_instance.barman_server[0].network_interface.0.access_config.0.nat_ip}
%{endfor~}
%{for count in range(var.hammerdb_server["count"])~}
Host hammerdbserver${count+1}
    User ${var.ssh_user}
    Hostname ${google_compute_instance.hammerdb_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
%{for count in range(var.pooler_server["count"])~}
%{if var.pooler_type == "pgpool2"~}
Host pgpool2${count+1}
%{else~}
Host pgbouncer${count+1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${google_compute_instance.pooler_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
    EOT
}
