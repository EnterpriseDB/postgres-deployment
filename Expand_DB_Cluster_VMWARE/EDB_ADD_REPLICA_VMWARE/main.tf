data "terraform_remote_state" "DB_CLUSTER" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster_VMWARE/terraform.tfstate"
  }
}

data "terraform_remote_state" "PEM_SERVER" {
  backend = "local"

  config = {
    path = "../${path.root}/PEM_Server_VMWARE/terraform.tfstate"
  }
}

data "vsphere_datacenter" "dc" {
  name = var.dcname
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  DBUSERPG="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  CPUCORE="${var.cpucore == "" ? "2" : var.cpucore}"
  RAM="${var.ramsize == "" ? "1024" : var.ramsize}"
  CLUSTERNAME="${data.terraform_remote_state.DB_CLUSTER.outputs.CLUSTER_NAME == "" ? data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE : data.terraform_remote_state.DB_CLUSTER.outputs.CLUSTER_NAME}"
}



resource "vsphere_virtual_machine" "Expand_DB_Cluster" {
  name             = "${local.CLUSTERNAME}-standby3"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  wait_for_guest_ip_timeout =    -1
  num_cpus = local.CPUCORE
  memory   = local.RAM
  guest_id = "centos7_64Guest"
  
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

provisioner "local-exec" {
    command = "echo '${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' > ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]

connection {
     host = self.default_ip_address
     type =  "ssh"
     user = var.ssh_user
     password = var.ssh_password
     port = "22"
     agent = false
}

}

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  '${path.module}/utilities/scripts/install${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address}" 
}


}


######################################

## Addition of new node in replicaset begins here

#####################################


resource "null_resource" "configure_streaming_replication" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address}"
  }

  depends_on = [vsphere_virtual_machine.Expand_DB_Cluster]

  provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Master-IP} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
} 

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-IP} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-IP} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
}



provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-IP} ip2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-IP} ip3=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-IP} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} REPLICATION_TYPE=${var.replication_type} MASTER=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-IP} SLAVE1=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-IP} SLAVE2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-IP} NEWSLAVE=${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}'"

}

}

resource "null_resource" "configureefm" {

triggers = {
    server-ip-address = "${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address}"
  }

depends_on = [null_resource.configure_streaming_replication]

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts ${path.module}/utilities/scripts/configureefm.yml --extra-vars='ip1=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-IP} ip2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-IP} ip3=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-IP} EFM_USER_PASSWORD=${var.efm_role_password} selfip=${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address} USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} SLAVE1=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-IP} SLAVE2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-IP} NEWSLAVE=${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address} MASTER=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-IP} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}'"

}

}


resource "null_resource" "configurepemagent" {

triggers = { 
    path = "${path.root}/PEM_Server_VMWARE"
  }

depends_on = [ 
   vsphere_virtual_machine.Expand_DB_Cluster,
   null_resource.configureefm
]

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${local.DBPASS} PEM_IP=${data.terraform_remote_state.PEM_SERVER.outputs.PEM_SERVER_IP} PEM_WEB_PASSWORD=${var.pem_web_ui_password} USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${vsphere_virtual_machine.Expand_DB_Cluster.default_ip_address}"

}

}

