resource "local_file" "AnsiblePEMYamlInventory" {
  count    = var.instance_count
  filename = var.ansible_pem_inventory_yaml_filename
  content  = <<EOT
---
servers:
  %{for count in range(var.instance_count)~}
%{if count == 0}pemserver:%{endif}%{if count == 1}primary${count}:%{endif}%{if count > 1}standby${count}:%{endif}
    node_type: %{if count == 0}pemserver%{endif}%{if count == 1}primary%{endif}%{if count > 1}standby%{endif}
    public_ip: ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.access_config.0.nat_ip}
    private_ip: ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.network_ip}
    %{if count > 1}replication_type: ${var.synchronicity}%{endif}
    %{if count > 0}pem_agent: true%{endif}
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
ssh-add -l ${var.ssh_key_location}
echo "Adding IPs"
%{for count in range(var.instance_count)~}
ssh-keyscan -H ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.edb-prereq-engine-instance[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}    
    EOT
}
