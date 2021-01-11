resource "local_file" "AnsibleYamlInventory" {
  count    = var.instance_count
  filename = var.ansible_inventory_yaml_filename
  content  = <<EOT
---
all:
  children:
  %{for count in range(var.instance_count)~}
%{if var.pem_instance_count == "1" && count == 0}
    pemserver:
      hosts:
        pemserver${count + 1}:%{endif}
%{if var.pem_instance_count == "0" || var.pem_instance_count == "1" && count == 1}
    primary:
      hosts:
        primary${count}:%{endif}
%{if var.pem_instance_count == "0" && count == "1" || var.pem_instance_count == "1" && count == 2}
    standby:
      hosts:
%{endif}
%{if count > 1}
        standby${count}:%{endif}
          ansible_host: ${google_compute_instance.vm[count].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.vm[count].network_interface.0.network_ip}
%{if count > 1}
          replication_type: ${var.synchronicity}%{endif}
%{if count > 0}
          pem_agent: true%{endif}
%{if var.pem_instance_count == "1"}
          pem_server_private_ip: ${google_compute_instance.vm[0].network_interface.0.network_ip}%{endif}
%{if var.pem_instance_count == "1" && count > 1}
          upstream_node_private_ip: ${google_compute_instance.vm[1].network_interface.0.network_ip}%{endif}
%{if var.pem_instance_count == "0" && count > 0}
          upstream_node_private_ip: ${google_compute_instance.vm[0].network_interface.0.network_ip}%{endif}
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
ssh-keyscan -H ${google_compute_instance.vm[count].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.vm[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
    EOT
}

resource "local_file" "hosts" {
  count    = var.instance_count
  filename = var.hosts_filename
  content  = <<EOT
  %{for count in range(var.instance_count)~}
  ${google_compute_instance.vm[count].network_interface.0.access_config.0.nat_ip}
  %{endfor~}
EOT
}
