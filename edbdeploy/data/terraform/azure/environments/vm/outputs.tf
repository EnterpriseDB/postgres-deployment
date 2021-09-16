resource "local_file" "AnsibleYamlInventory" {
  filename = "${abspath(path.root)}/${var.ansible_inventory_yaml_filename}"
  content  = <<EOT
---
all:
  children:
%{if var.pem_server["count"] > 0~}
    pemserver:
      hosts:
        pemserver1.${var.cluster_name}.internal:
          ansible_host: ${azurerm_public_ip.pem_public_ip[0].ip_address}
          private_ip: ${azurerm_network_interface.pem_public_nic[0].private_ip_address}
%{endif~}
%{if var.barman_server["count"] > 0~}
    barmanserver:
      hosts:
        barmanserver1.${var.cluster_name}.internal:
          ansible_host: ${azurerm_public_ip.barman_public_ip[0].ip_address}
          private_ip: ${azurerm_network_interface.barman_public_nic[0].private_ip_address}
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
%{if postgres_count >= 0~}
%{if var.pg_type == "EPAS"~}
        epas${postgres_count + 1}.${var.cluster_name}.internal:
%{else~}
        pgsql${postgres_count + 1}.${var.cluster_name}.internal:
%{endif~}
%{endif~}
          ansible_host: ${azurerm_public_ip.postgres_public_ip[postgres_count].ip_address}
          private_ip: ${azurerm_network_interface.postgres_public_nic[postgres_count].private_ip_address}
%{if var.barman == true~}
          barman: true
          barman_server_private_ip: ${azurerm_network_interface.barman_public_nic[0].private_ip_address}
          barman_backup_method: postgres
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
          upstream_node_private_ip: ${azurerm_network_interface.postgres_public_nic[0].private_ip_address}
%{endif~}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${azurerm_network_interface.pem_public_nic[0].private_ip_address}
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
        pooler${pooler_count + 1}:
          ansible_host: ${azurerm_public_ip.pooler_public_ip[pooler_count].ip_address}
          private_ip: ${azurerm_network_interface.pooler_public_nic[pooler_count].private_ip_address}
          primary_private_ip: ${azurerm_network_interface.postgres_public_nic[0].private_ip_address}
%{endfor~}
EOT
}

resource "local_file" "host_script" {
  filename = var.add_hosts_filename
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{for count in range(var.postgres_server["count"])~}
ssh-keyscan -H ${azurerm_public_ip.postgres_public_ip[count].ip_address} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${azurerm_public_ip.postgres_public_ip[count].ip_address}
%{endfor~}
%{if var.pem_server["count"] > 0~}
ssh-keyscan -H ${azurerm_public_ip.pem_public_ip[0].ip_address} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${azurerm_public_ip.pem_public_ip[0].ip_address}
%{endif~}
%{if var.barman_server["count"] > 0~}
ssh-keyscan -H ${azurerm_public_ip.barman_public_ip[0].ip_address} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${azurerm_public_ip.barman_public_ip[0].ip_address}
%{endif~}
%{for count in range(var.pooler_server["count"])~}
ssh-keyscan -H ${azurerm_public_ip.pooler_public_ip[count].ip_address} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${azurerm_public_ip.pooler_public_ip[count].ip_address}
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
