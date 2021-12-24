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
          ansible_host: ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.pem_server[0].network_interface.0.network_ip}
%{endif~}
%{if var.dbt2_client["count"] > 0~}
    dbt2_client:
      hosts:
%{for dbt2_client_count in range(var.dbt2_client["count"])~}
        dbt2_client${dbt2_client_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${google_compute_instance.dbt2_client[dbt2_client_count].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.dbt2_client[dbt2_client_count].network_interface.0.network_ip}
%{endfor~}
%{endif~}
%{if var.dbt2_driver["count"] > 0~}
    dbt2_driver:
      hosts:
%{for dbt2_driver_count in range(var.dbt2_driver["count"])~}
        dbt2_driver${dbt2_driver_count + 1}.${var.cluster_name}.internal:
          ansible_host: ${google_compute_instance.dbt2_driver[dbt2_driver_count].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.dbt2_driver[dbt2_driver_count].network_interface.0.network_ip}
%{endfor~}
%{endif~}
%{for hammerdb_count in range(var.hammerdb_server["count"])~}
%{if hammerdb_count == 0~}
    hammerdbserver:
      hosts:
        hammerdbserver1:
          ansible_host: ${google_compute_instance.hammerdb_server[hammerdb_count].network_interface.0.access_config.0.nat_ip}
          private_ip: ${google_compute_instance.hammerdb_server[hammerdb_count].network_interface.0.network_ip}
%{endif~}
%{endfor~}
    primary:
      hosts:
        primary1:
          ansible_host: ${google_sql_database_instance.postgresql.public_ip_address}
          private_ip: ${google_sql_database_instance.postgresql.public_ip_address}
%{if var.pem_server["count"] > 0~}
          pem_agent: true
          pem_server_private_ip: ${google_compute_instance.pem_server[0].network_interface.0.network_ip}
%{endif~}
EOT
}

resource "local_file" "host_script" {
  filename = var.add_hosts_filename
  content  = <<-EOT
echo "Setting SSH Keys"
ssh-add ${var.ssh_priv_key}
echo "Adding IPs"
%{if var.pem_server["count"] > 0~}
ssh-keyscan -H ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${google_compute_instance.pem_server[0].network_interface.0.access_config.0.nat_ip}
%{endif~}
    EOT
}

resource "local_file" "postgresql" {
  filename = "postgresql.yml"
  content  = <<EOT
---
pg_superuser_override: ${google_sql_user.postgresql_user.name}
pg_superuser_password_override: ${random_id.user_password.hex}
pg_host: ${google_sql_database_instance.postgresql.public_ip_address}
EOT
}
