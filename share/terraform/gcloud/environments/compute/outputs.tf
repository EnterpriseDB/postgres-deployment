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
          ansible_host: ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.pem_server[0].network_interface.0.network_ip}%{endif}
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
          ansible_host: ${google_compute_instance.pg_server[count].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.pg_server[count].network_interface.0.network_ip}
%{if count > 0}
          replication_type: ${var.synchronicity}
          upstream_node_private_ip: ${google_compute_instance.pg_server[0].network_interface.0.network_ip}%{endif}
%{if var.pem_instance_count == 1}
          pem_agent: true
          pem_server_private_ip: ${google_compute_instance.pem_server[0].network_interface.0.network_ip}%{endif}
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
%{for count in range(var.pg_instance_count)~}
ssh-keyscan -H ${google_compute_instance.pg_server[count].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.pg_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor~}
%{if var.pem_instance_count == 1}
ssh-keyscan -H ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
%{endif}
    EOT
}

resource "local_file" "hosts" {
  filename = var.hosts_filename
  content  = <<EOT
  %{for count in range(var.pg_instance_count)~}
${google_compute_instance.pg_server[count].network_interface.0.access_config.0.nat_ip}
  %{endfor~}
  %{if var.pem_instance_count == 1}
${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
  %{endif}
EOT
}
