locals {
  server_count_map = {
    postgres_server = var.postgres_server
    pem_server = var.pem_server
    barman_server = var.barman_server
    pooler_server = var.pooler_server
    hammerdb_server = var.hammerdb_server
  }
  azurerm_public_ip_map = {
    postgres_server = azurerm_public_ip.postgres_public_ip
    pem_server = azurerm_public_ip.pem_public_ip
    barman_server = azurerm_public_ip.barman_public_ip
    pooler_server = azurerm_public_ip.pooler_public_ip
    hammerdb_server = azurerm_public_ip.hammerdb_public_ip
  }
  azurerm_public_nic_map = {
    postgres_server = azurerm_network_interface.postgres_public_nic
    pem_server = azurerm_network_interface.pem_public_nic
    barman_server = azurerm_network_interface.barman_public_nic
    pooler_server = azurerm_network_interface.pooler_public_nic
    hammerdb_server = azurerm_network_interface.hammerdb_public_nic
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
