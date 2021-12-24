locals {
  server_count_map = {
    postgres_server = var.postgres_server
    pem_server = var.pem_server
    bdr_server = var.bdr_server
    bdr_witness_server = var.bdr_witness_server
    barman_server = var.barman_server
    pooler_server = var.pooler_server
    dbt2_client = var.dbt2_client
    dbt2_driver = var.dbt2_driver
    hammerdb_server = var.hammerdb_server
  }
  aws_instance_map = {
    postgres_server = aws_instance.postgres_server
    pem_server = aws_instance.pem_server
    bdr_server = aws_instance.bdr_server
    bdr_witness_server = aws_instance.bdr_witness_server
    barman_server = aws_instance.barman_server
    pooler_server = aws_instance.pooler_server
    dbt2_client = aws_instance.dbt2_client
    dbt2_driver = aws_instance.dbt2_driver
    hammerdb_server = aws_instance.hammerdb_server
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
ssh-keyscan -H ${local.aws_instance_map[k][count].public_ip} >> ~/.ssh/known_hosts
ssh-keyscan -H ${local.aws_instance_map[k][count].public_ip} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${local.aws_instance_map[k][count].public_dns}
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
      public_ip: ${local.aws_instance_map[k][count].public_ip}
      private_ip: ${local.aws_instance_map[k][count].private_ip}
%{endfor~}
%{endif~}
%{endfor~}
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
