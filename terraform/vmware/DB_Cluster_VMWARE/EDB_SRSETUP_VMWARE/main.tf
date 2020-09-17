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

resource "vsphere_virtual_machine" "EDB_SR_SETUP" {
  name                      = count.index == 0 ? "${local.CLUSTER_NAME}-master" : "${local.CLUSTER_NAME}-standby${count.index}"
  count                     = 3
  resource_pool_id          = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id              = data.vsphere_datastore.datastore.id
  wait_for_guest_ip_timeout = -1
  num_cpus                  = local.CPUCORE
  memory                    = local.RAM
  guest_id                  = "centos7_64Guest"

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  provisioner "local-exec" {
    command = "echo '${self.default_ip_address} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    inline = [
      "yum info python"
    ]

    connection {
      host     = self.default_ip_address
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      port     = "22"
      agent    = false
    }

  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  '${path.module}/utilities/scripts/install${var.dbengine}.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${self.default_ip_address}"
  }


}


locals {
  DBUSERPG     = "${var.db_user == "" || var.dbengine == regexall("${var.dbengine}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS   = "${var.db_user == "" || var.dbengine == regexall("${var.dbengine}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS       = "${var.db_password == "" ? "postgres" : var.db_password}"
  CPUCORE      = "${var.cpucore == "" ? "2" : var.cpucore}"
  RAM          = "${var.ramsize == "" ? "1024" : var.ramsize}"
  CLUSTER_NAME = "${var.cluster_name == "" ? var.dbengine : var.cluster_name}"
}

#####################################
## Configuration of streaming replication start here
#
#
########################################### 

resource "null_resource" "configuremaster" {
  triggers = {
    private_ip = "${join(",", vsphere_virtual_machine.EDB_SR_SETUP.*.default_ip_address)}"
  }

  depends_on = [vsphere_virtual_machine.EDB_SR_SETUP[0]]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts '${path.module}/utilities/scripts/configuremaster.yml' --extra-vars='ip1=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} ip2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} ip3=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} REPLICATION_TYPE=${var.replication_type} DBPASSWORD=${local.DBPASS}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}"

  }

}

resource "null_resource" "configureslave1" {
  triggers = {
    private_ip = "${join(",", vsphere_virtual_machine.EDB_SR_SETUP.*.default_ip_address)}"
  }

  depends_on = [null_resource.configuremaster]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} ip2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} REPLICATION_TYPE=${var.replication_type} SLAVE1=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} SLAVE2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} MASTER=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}"

  }

}



resource "null_resource" "configureslave2" {
  triggers = {
    private_ip = "${join(",", vsphere_virtual_machine.EDB_SR_SETUP.*.default_ip_address)}"
  }

  depends_on = [null_resource.configuremaster]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} ip2=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} REPLICATION_TYPE=${var.replication_type} SLAVE1=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} SLAVE2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} MASTER=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}"

  }

}

resource "null_resource" "removehostfile" {

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/utilities/scripts/hosts"
  }

  depends_on = [
    null_resource.configureslave2,
    null_resource.configureslave1,
    null_resource.configuremaster,
    vsphere_virtual_machine.EDB_SR_SETUP

  ]
}

