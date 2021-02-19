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
%{if var.barman_server["count"] > 0 ~}
    barmanserver:
      hosts:
        barmanserver1:
          ansible_host: ${aws_instance.barman_server[0].public_ip}
          private_ip: ${aws_instance.barman_server[0].private_ip}
%{endif ~}
%{if var.hammerdb_server["count"] > 0 ~}
    hammerdbserver:
      hosts:
        hammerdbserver1:
          ansible_host: ${aws_instance.hammerdb_server[0].public_ip}
          private_ip: ${aws_instance.hammerdb_server[0].private_ip}
%{endif ~}
%{for postgres_count in range(var.postgres_server["count"]) ~}
%{if postgres_count == 0 ~}
    primary:
      hosts:
        primary${postgres_count + 1}:
%{endif ~}
%{if postgres_count == 1 ~}
    standby:
      hosts:
%{endif ~}
%{if postgres_count > 0 ~}
        standby${postgres_count}:
%{endif ~}
          ansible_host: ${aws_instance.postgres_server[postgres_count].public_ip}
          private_ip: ${aws_instance.postgres_server[postgres_count].private_ip}
%{if var.barman == true ~}
          barman: true
          barman_server_private_ip: ${aws_instance.barman_server[0].private_ip}
          barman_backup_method: postgres
%{endif ~}
%{if var.hammerdb == true ~}
          hammerdb: true
          hammerdb_server_private_ip: ${aws_instance.hammerdb_server[0].private_ip}
%{endif ~}
%{if var.pooler_local == true && var.pooler_type == "pgbouncer" ~}
          pgbouncer: true
%{endif ~}
%{if postgres_count > 0 ~}
%{if postgres_count == 1 ~}
          replication_type: ${var.replication_type}
%{else ~}
          replication_type: asynchronous
%{endif ~}
          upstream_node_private_ip: ${aws_instance.postgres_server[0].private_ip}
%{endif ~}
%{if var.pem_server["count"] > 0 ~}
          pem_agent: true
          pem_server_private_ip: ${aws_instance.pem_server[0].private_ip}
%{endif ~}
%{endfor ~}
%{for pooler_count in range(var.pooler_server["count"]) ~}
%{if pooler_count == 0 ~}
%{if var.pooler_type == "pgpool2" ~}
    pgpool2:
%{endif ~}
%{if var.pooler_type == "pgbouncer" ~}
    pgbouncer:
%{endif ~}
      hosts:
%{endif ~}
        pooler${pooler_count + 1}:
          ansible_host: ${aws_instance.pooler_server[pooler_count].public_ip}
          private_ip: ${aws_instance.pooler_server[pooler_count].private_ip}
          primary_private_ip: ${aws_instance.postgres_server[0].private_ip}
%{endfor ~}
EOT
}

resource "local_file" "host_script" {
  filename = "${abspath(path.root)}/${var.add_hosts_filename}"
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{for count in range(var.postgres_server["count"]) ~}
ssh-keyscan -H ${aws_instance.postgres_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.postgres_server[count].public_dns}
%{endfor ~}
%{if var.pem_server["count"] > 0 ~}
ssh-keyscan -H ${aws_instance.pem_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pem_server[0].public_dns}
%{endif ~}
%{if var.barman_server["count"] > 0 ~}
ssh-keyscan -H ${aws_instance.barman_server[0].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.barman_server[0].public_dns}
%{endif ~}
%{for count in range(var.pooler_server["count"]) ~}
ssh-keyscan -H ${aws_instance.pooler_server[count].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.pooler_server[count].public_dns}
%{endfor ~}
    EOT
}
