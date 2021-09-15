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
          ansible_host: ${aws_instance.pem_server[0].public_ip}
          private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif~}
%{if var.dbt2_client["count"] > 0~}
    dbt2_client:
      hosts:
%{for dbt2_client_count in range(var.dbt2_client["count"])~}
        dbt2_client${dbt2_client_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${aws_instance.dbt2_client[dbt2_client_count].public_ip}
          private_ip: ${aws_instance.dbt2_client[dbt2_client_count].private_ip}
%{endfor~}
%{endif~}
%{if var.dbt2_driver["count"] > 0~}
    dbt2_driver:
      hosts:
%{for dbt2_driver_count in range(var.dbt2_driver["count"])~}
        dbt2_driver${dbt2_driver_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${aws_instance.dbt2_driver[dbt2_driver_count].public_ip}
          private_ip: ${aws_instance.dbt2_driver[dbt2_driver_count].private_ip}
%{endfor~}
%{endif~}
%{if var.dbt2 == true~}
          dbt2: true
%{for dbt2_client_count in range(var.dbt2_client["count"])~}
          dbt2_client_private_ip${dbt2_client_count + 1}: ${aws_instance.dbt2_client[dbt2_client_count].private_ip}
%{endfor~}
%{endif~}
%{if var.hammerdb_server["count"] > 0~}
    hammerdbserver:
      hosts:
        hammerdbserver1:
          ansible_host: ${aws_instance.hammerdb_server[0].public_ip}
          private_ip: ${aws_instance.hammerdb_server[0].private_ip}
%{endif~}
    primary:
      hosts:
        primary1:
          ansible_host: ${aws_db_instance.rds_server.address}
          private_ip: ${aws_db_instance.rds_server.address}
EOT
}

resource "local_file" "host_script" {
  filename = "${abspath(path.root)}/${var.add_hosts_filename}"
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{if var.pem_server["count"] > 0~}
ssh-keyscan -H ${aws_instance.pem_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pem_server[0].public_dns}
%{endif~}
    EOT
}
