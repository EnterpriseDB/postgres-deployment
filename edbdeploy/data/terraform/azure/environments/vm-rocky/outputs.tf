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
  }
  azurerm_public_ip_map = {
    postgres_server = azurerm_public_ip.postgres_public_ip
    bdr_server = azurerm_public_ip.bdr_public_ip
    bdr_witness_server = azurerm_public_ip.bdr_witness_public_ip
    pem_server = azurerm_public_ip.pem_public_ip
    barman_server = azurerm_public_ip.barman_public_ip
    pooler_server = azurerm_public_ip.pooler_public_ip
    dbt2_client = azurerm_public_ip.dbt2_client_public_ip
    dbt2_driver = azurerm_public_ip.dbt2_driver_public_ip
  }
  azurerm_public_nic_map = {
    postgres_server = azurerm_network_interface.postgres_public_nic
    bdr_server = azurerm_network_interface.bdr_public_nic
    bdr_witness_server = azurerm_network_interface.bdr_witness_public_nic
    pem_server = azurerm_network_interface.pem_public_nic
    barman_server = azurerm_network_interface.barman_public_nic
    pooler_server = azurerm_network_interface.pooler_public_nic
    dbt2_client = azurerm_network_interface.dbt2_client_public_nic
    dbt2_driver = azurerm_network_interface.dbt2_driver_public_nic
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
ssh-keyscan -H ${local.azurerm_public_ip_map[k][count].ip_address} >> ~/.ssh/known_hosts
ssh-keyscan -H ${local.azurerm_public_ip_map[k][count].ip_address} >> tpa_known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${local.azurerm_public_ip_map[k][count].ip_address}
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
      public_ip: ${local.azurerm_public_ip_map[k][count].ip_address}
      private_ip: ${local.azurerm_public_nic_map[k][count].private_ip_address}
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
    Hostname ${azurerm_public_ip.postgres_public_ip[count].ip_address}
%{endfor~}
%{for count in range(var.bdr_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${count+1}
%{else~}
Host pgsql${count+1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${azurerm_public_ip.bdr_public_ip[count].ip_address}
%{endfor~}
%{for count in range(var.bdr_witness_server["count"])~}
%{if var.pg_type == "EPAS"~}
Host epas${count+1}
%{else~}
Host pgsql${count+1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${azurerm_public_ip.bdr_witness_public_ip[count].ip_address}
%{endfor~}
%{if var.pem_server["count"] > 0~}
Host pemserver1
    User ${var.ssh_user}
    Hostname ${azurerm_public_ip.pem_public_ip[0].ip_address}
%{endif~}
%{for count in range(var.barman_server["count"])~}
Host barmanserver${count+1}
    User ${var.ssh_user}
    Hostname ${azurerm_public_ip.barman_public_ip[0].ip_address}
%{endfor~}
%{for count in range(var.pooler_server["count"])~}
%{if var.pooler_type == "pgpool2"~}
Host pgpool2${count+1}
%{else~}
Host pgbouncer${count+1}
%{endif~}
    User ${var.ssh_user}
    Hostname ${azurerm_public_ip.pooler_public_ip[count].ip_address}
%{endfor~}
    EOT
}
