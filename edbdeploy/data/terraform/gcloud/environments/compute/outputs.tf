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
          ansible_host: ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.pem_server[0].network_interface.0.network_ip}
%{endif ~}
%{if var.barman_server["count"] > 0 ~}
    barmanserver:
      hosts:
        barmanserver1:
          ansible_host: ${google_compute_instance.barman_server[0].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.barman_server[0].network_interface.0.network_ip}
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
          ansible_host: ${google_compute_instance.postgres_server[postgres_count].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.postgres_server[postgres_count].network_interface.0.network_ip}
%{if var.barman == true ~}
          barman: true
          barman_server_private_ip: ${google_compute_instance.barman_server[0].network_interface.0.network_ip}
          barman_backup_method: postgres
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
          upstream_node_private_ip: ${google_compute_instance.postgres_server[0].network_interface.0.network_ip}
%{endif ~}
%{if var.pem_server["count"] > 0 ~}
          pem_agent: true
          pem_server_private_ip: ${google_compute_instance.pem_server[0].network_interface.0.network_ip}
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
          ansible_host: ${google_compute_instance.pooler_server[pooler_count].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.pooler_server[pooler_count].network_interface.0.network_ip}
          primary_private_ip: ${google_compute_instance.postgres_server[0].network_interface.0.network_ip}
%{endfor ~}
EOT
}

resource "local_file" "host_script" {
  filename = var.add_hosts_filename
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{for count in range(var.postgres_server["count"]) ~}
ssh-keyscan -H ${google_compute_instance.postgres_server[count].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.postgres_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor ~}
%{if var.pem_server["count"] > 0 ~}
ssh-keyscan -H ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
%{endif ~}
%{if var.barman_server["count"] > 0 ~}
ssh-keyscan -H ${google_compute_instance.barman_server[0].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.barman_server[0].network_interface.0.access_config.0.nat_ip}
%{endif ~}
%{for count in range(var.pooler_server["count"]) ~}
ssh-keyscan -H ${google_compute_instance.pooler_server[count].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.pooler_server[count].network_interface.0.access_config.0.nat_ip}
%{endfor ~}
    EOT
}
