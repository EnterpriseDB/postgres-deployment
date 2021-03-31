resource "local_file" "AnsibleYamlInventory" {
  filename = "${abspath(path.root)}/${var.ansible_inventory_yaml_filename}"
  content  = <<EOT
---
all:
  children:
%{if var.pem_server["count"] > 0 ~}
    pemserver:
      hosts:
        pemserver1:
          ansible_host: ${aws_instance.pem_server[0].public_ip}
          private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif ~}
%{if var.hammerdb_server["count"] > 0 ~}
    hammerdbserver:
      hosts:
        hammerdbserver1:
          ansible_host: ${aws_instance.hammerdb_server[0].public_ip}
          private_ip: ${aws_instance.hammerdb_server[0].private_ip}
%{endif ~}
    primary:
      hosts:
        primary1:
          ansible_host: ${aws_rds_cluster.rds_server.endpoint}
          private_ip: ${aws_rds_cluster.rds_server.endpoint}
EOT
}

resource "local_file" "host_script" {
  filename = "${abspath(path.root)}/${var.add_hosts_filename}"
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{if var.pem_server["count"] > 0 ~}
ssh-keyscan -H ${aws_instance.pem_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pem_server[0].public_dns}
%{endif ~}
    EOT
}
