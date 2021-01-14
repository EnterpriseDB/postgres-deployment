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
          ansible_host: ${aws_instance.pem_server[0].public_ip}
          private_ip: ${aws_instance.pem_server[0].private_ip}%{endif}
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
          ansible_host: ${aws_instance.pg_server[count].public_ip}
          private_ip: ${aws_instance.pg_server[count].private_ip}
%{if count > 0}
          replication_type: ${var.synchronicity}
          upstream_node_private_ip: ${aws_instance.pg_server[0].private_ip}%{endif}
%{if var.pem_instance_count == 1}
          pem_agent: true
          pem_server_private_ip: ${aws_instance.pem_server[0].private_ip}%{endif}
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
ssh-add ${var.ssh_key_path}
echo "Adding IPs"

%{for count in range(var.pg_instance_count)~}
ssh-keyscan -H ${aws_instance.pg_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pg_server[count].public_dns}
%{endfor~}
%{if var.pem_instance_count == 1}
ssh-keyscan -H ${aws_instance.pem_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pem_server[0].public_dns}
%{endif}
    EOT
}
