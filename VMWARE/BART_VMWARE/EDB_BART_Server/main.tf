data "terraform_remote_state" "SR" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster_VMWARE/terraform.tfstate"
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
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  CPUCORE="${var.cpucore == "" ? "2" : var.cpucore}"
  RAM="${var.ramsize == "" ? "1024" : var.ramsize}"
}

resource "vsphere_virtual_machine" "BART_SERVER" {
  name             = "edb-bart-server-new"
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

 disk {
     label = "disk1"
     unit_number = 1
     size = var.size
     datastore_id = data.vsphere_datastore.datastore.id
}
 
clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

provisioner "local-exec" {
    command = "echo '${vsphere_virtual_machine.BART_SERVER.default_ip_address} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' > ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Master-IP} ansible_user=${data.terraform_remote_state.SR.outputs.SSH-USER} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]

connection {
     host = vsphere_virtual_machine.BART_SERVER.default_ip_address
     type =  "ssh"
     user = var.ssh_user
     password = var.ssh_password
     port = "22"
     agent = false
}

}

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  '${path.module}/utilities/scripts/bartserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_USER=${var.db_user} BART_IP=${vsphere_virtual_machine.BART_SERVER.default_ip_address} DB_IP=${data.terraform_remote_state.SR.outputs.Master-IP} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} DB_PASSWORD=${var.db_password} RETENTION_PERIOD=\"${var.retention_period}\"'" 

}

}

resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
    vsphere_virtual_machine.BART_SERVER
]
}

