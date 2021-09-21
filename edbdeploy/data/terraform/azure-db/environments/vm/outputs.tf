resource "local_file" "AnsibleYamlInventory" {
  filename = "${abspath(path.root)}/${var.ansible_inventory_yaml_filename}"
  content  = <<EOT
---
all:
  children:
%{if var.pem_server["count"] > 0~}
    pemserver:
      hosts:
        pemserver1:
          ansible_host: ${azurerm_public_ip.pem_public_ip[0].ip_address}
          private_ip: ${azurerm_network_interface.pem_public_nic[0].private_ip_address}
%{endif~}
%{if var.dbt2_client["count"] > 0~}
    dbt2_client:
      hosts:
%{for dbt2_client_count in range(var.dbt2_client["count"])~}
        dbt2_client${dbt2_client_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${azurerm_public_ip.dbt2_client_public_ip[0].ip_address}
          private_ip: ${azurerm_network_interface.dbt2_client_public_nic[0].private_ip_address}
%{endfor~}
%{endif~}
%{if var.dbt2_driver["count"] > 0~}
    dbt2_driver:
      hosts:
%{for dbt2_driver_count in range(var.dbt2_driver["count"])~}
        dbt2_driver${dbt2_driver_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${azurerm_public_ip.dbt2_driver_public_ip[0].ip_address}
          private_ip: ${azurerm_network_interface.dbt2_driver_public_nic[0].private_ip_address}
%{endfor~}
%{endif~}
%{if var.hammerdb_server["count"] > 0~}
    hammerdbserver:
      hosts:
        hammerdbserver1:
          ansible_host: ${azurerm_public_ip.hammerdb_public_ip[0].ip_address}
          private_ip: ${azurerm_network_interface.hammerdb_public_nic[0].private_ip_address}
%{endif~}
%{for postgres_count in range(var.postgres_server["count"])~}
%{if postgres_count == 0~}
    primary:
      hosts:
        primary${postgres_count + 1}:
%{endif~}
%{if postgres_count == 1~}
    standby:
      hosts:
%{endif~}
%{if postgres_count > 0~}
        standby${postgres_count}:
%{endif~}
          ansible_host: ${azurerm_public_ip.postgres_public_ip[postgres_count].ip_address}
          private_ip: ${azurerm_network_interface.postgres_public_nic[postgres_count].private_ip_address}
%{if var.hammerdb == true~}
          hammerdb: true
          hammerdb_server_private_ip: ${azurerm_network_interface.hammerdb_public_nic[0].private_ip_address}
%{endif~}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${azurerm_network_interface.pem_public_nic[0].private_ip_address}
%{endif~}
%{endfor~}
    primary:
      hosts:
        primary1:
          ansible_host: ${azurerm_postgresql_server.postgresql_server.fqdn}
          private_ip: ${azurerm_postgresql_server.postgresql_server.fqdn}
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
    EOT
}

resource "local_file" "postgresql" {
  filename = "postgresql.yml"
  content  = <<EOT
---
pg_superuser_override: ${azurerm_postgresql_server.postgresql_server.administrator_login}
pg_superuser_connect: ${azurerm_postgresql_server.postgresql_server.administrator_login}@${azurerm_postgresql_server.postgresql_server.name}
pg_superuser_password_override: ${azurerm_postgresql_server.postgresql_server.administrator_login_password}
pg_host: ${azurerm_postgresql_server.postgresql_server.name}
EOT
}
