resource "local_file" "AnsibleYamlInventory" {
  count    = var.instance_count
  filename = var.ansible_inventory_yaml_filename
  content  = <<EOT
---
servers:
  %{for count in range(var.instance_count)~}
server${count}:
    node_type: %{if count == 0}primary%{else}standby%{endif}
    public_ip: ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.access_config.0.nat_ip}
    private_ip: ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.network_ip}
    replication_type: synchronous
  %{endfor~}
EOT
}

resource "local_file" "AnsibleOSCSVFile" {
  filename = var.os_csv_filename
  content  = <<EOT
os_name_and_version
${var.os}
EOT
}

resource "local_file" "host_script" {
  filename = var.add_hosts_filename
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_key_location}
echo "Adding IPs"
%{for count in range(var.instance_count)~}
ssh-keyscan -H ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}    
    EOT
}
