resource "local_file" "AnsiblePEMYamlInventory" {
  count    = var.instance_count
  filename = var.ansible_pem_inventory_yaml_filename
  content  = <<EOT
---
servers:
  %{for count in range(var.instance_count)~}
%{if count == 0}pemserver:%{endif}%{if count == 1}primary${count}:%{endif}%{if count > 1}standby${count}:%{endif}
    node_type: %{if count == 0}pemserver%{endif}%{if count == 1}primary%{endif}%{if count > 1}standby%{endif}
    public_ip: ${azurerm_public_ip.publicip[count].ip_address}
    private_ip: ${azurerm_network_interface.Public_Nic[count].private_ip_address}
    %{if count > 1}replication_type: ${var.synchronicity}%{endif}
    %{if count > 0}pem_agent: true%{endif}
  %{endfor~}
EOT
}

resource "local_file" "AnsibleYamlInventory" {
  count    = var.instance_count
  filename = var.ansible_inventory_yaml_filename
  content  = <<EOT
---
servers:
  %{for count in range(var.instance_count)~}
server${count}:
    node_type: %{if count == 0}primary%{else}standby%{endif}
    public_ip: ${azurerm_public_ip.publicip[count].ip_address}
    private_ip: ${azurerm_network_interface.Public_Nic[count].private_ip_address}
    %{if count > 1}replication_type: ${var.synchronicity}%{endif}
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
%{for count in range(var.instance_count)~}
ssh-keyscan -H ${azurerm_public_ip.publicip[count].ip_address} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${azurerm_public_ip.publicip[count].ip_address}
%{endfor~}    
    EOT
}
