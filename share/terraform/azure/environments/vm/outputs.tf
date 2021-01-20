resource "local_file" "AnsibleYamlInventory" {
  filename = var.ansible_inventory_yaml_filename
  content  = <<EOT
---
all:
  children:
%{if var.pem_instance_count == 1}
    pemserver:
      hosts:
        pemserver1:
          ansible_host: ${azurerm_public_ip.all_public_ip[var.pg_instance_count].ip_address}
          private_ip: ${azurerm_network_interface.all_public_nic[var.pg_instance_count].private_ip_address}%{endif}
  %{for count in range(var.pg_instance_count)~}
%{if count == 0}
    primary:
      hosts:
        primary${count + 1}:%{endif}
%{if count == 1}
    standby:
      hosts:%{endif}
%{if count > 0}
        standby${count}:%{endif}
          ansible_host: ${azurerm_public_ip.all_public_ip[count].ip_address}
          private_ip: ${azurerm_network_interface.all_public_nic[count].private_ip_address}
%{if count > 0}
          replication_type: ${var.synchronicity}
          upstream_node_private_ip: ${azurerm_network_interface.all_public_nic[0].private_ip_address}%{endif}
%{if var.pem_instance_count == 1}
          pem_agent: true
          pem_server_private_ip: ${azurerm_network_interface.all_public_nic[var.pg_instance_count].private_ip_address}%{endif}
  %{endfor~}
EOT
}

resource "local_file" "AnsibleOSCSVFile" {
  filename = var.os_csv_filename
  content  = <<EOT
os_name_and_version
${var.offer}${var.sku}
EOT
}

resource "local_file" "host_script" {
  filename = var.add_hosts_filename
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_key_path}
echo "Adding IPs"
%{for count in range(var.pg_instance_count)~}
ssh-keyscan -H ${azurerm_public_ip.all_public_ip[count].ip_address} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${azurerm_public_ip.all_public_ip[count].ip_address}
%{endfor~}
%{if var.pem_instance_count == 1}
ssh-keyscan -H ${azurerm_public_ip.all_public_ip[var.pg_instance_count].ip_address} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${azurerm_public_ip.all_public_ip[var.pg_instance_count].ip_address}
%{endif}
    EOT
}
