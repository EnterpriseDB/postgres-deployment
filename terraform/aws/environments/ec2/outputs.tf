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
         pemserver${count+1}:%{endif}
%{if var.pem_instance_count == "0" || var.pem_instance_count == "1" && count == 1}
     primary:
       hosts:
         primary${count}:%{endif}
%{if var.pem_instance_count == "0" && count == "1" || var.pem_instance_count == "1" && count == 2 }
     standby:
       hosts:
%{endif}
%{if count > 1}
         standby${count}:%{endif}
           ansible_host: ${aws_instance.EDB_DB_Cluster[count].public_ip}
           private_ip: ${aws_instance.EDB_DB_Cluster[count].private_ip}
%{if count > 1}
           replication_type: ${var.synchronicity}%{endif}
%{if count > 0}
           pem_agent: true%{endif}
%{if var.pem_instance_count == "1"}
           pem_server_private_ip: ${aws_instance.EDB_DB_Cluster[0].private_ip}%{endif}
%{if var.pem_instance_count == "1" && count > 1}
           upstream_node_private_ip: ${aws_instance.EDB_DB_Cluster[1].private_ip}%{endif}
%{if var.pem_instance_count == "0" && count > 0}
           upstream_node_private_ip: ${aws_instance.EDB_DB_Cluster[0].private_ip}%{endif}
  %{endfor~}
EOT
}

resource "local_file" "AnsiblePEMYamlInventory" {
  count    = var.instance_count
  filename = var.ansible_pem_inventory_yaml_filename
  content  = <<EOT
---
servers:
  %{for count in range(var.instance_count)~}
%{if var.pem_instance_count == "1" && count == 0}pemserver:%{endif}%{if var.pem_instance_count == "0" || var.pem_instance_count == "1" && count == 1}primary${count}:%{endif}%{if count > 1}standby${count}:%{endif}
    node_type: %{if var.pem_instance_count == "1" && count == 0}pemserver%{endif}%{if var.pem_instance_count == "0" || count == 1}primary%{endif}%{if count > 1}standby%{endif}
    public_dns: ${aws_instance.EDB_DB_Cluster[count].public_dns}
    public_ip: ${aws_instance.EDB_DB_Cluster[count].public_ip}
    private_ip: ${aws_instance.EDB_DB_Cluster[count].private_ip}
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
ssh-add ${var.ssh_key_path}
echo "Adding IPs"

%{for count in range(var.instance_count)~}
ssh-keyscan -H ${aws_instance.EDB_DB_Cluster[count].public_ip} >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ${aws_instance.EDB_DB_Cluster[count].public_dns}
%{endfor~}    
    EOT
}
