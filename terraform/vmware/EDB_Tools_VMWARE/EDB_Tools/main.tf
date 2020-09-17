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
  name                      = count.index == 0 ? "${local.CLUSTERNAME}-master" : "${local.CLUSTERNAME}-slave${count.index}"
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
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  '${path.module}/utilities/scripts/installepas12.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} EPASDBUSER=${local.DBUSEREPAS}' --limit ${self.default_ip_address}"
  }

}


locals {
  DBUSEREPAS   = "${var.db_user == "" ? "enterprisedb" : var.db_user}"
  DBPASS       = "${var.db_password == "" ? "postgres" : var.db_user}"
  CPUCORE      = "${var.cpucore == "" ? "2" : var.cpucore}"
  RAM          = "${var.ramsize == "" ? "1024" : var.ramsize}"
  CPUCORE_PEM  = "${var.cpucore_pem == "" ? "2" : var.cpucore_pem}"
  RAM_PEM      = "${var.ramsize_pem == "" ? "1024" : var.ramsize_pem}"
  CPUCORE_BART = "${var.cpucore_bart == "" ? "2" : var.cpucore_bart}"
  RAM_BART     = "${var.ramsize_bart == "" ? "1024" : var.ramsize_bart}"
  CLUSTERNAME  = "${var.cluster_name == "" ? "epas12" : var.cluster_name}"
}

#####################################
## Configuration of streaming replication start here
#
#
########################################### 

resource "null_resource" "configuremaster" {

  depends_on = [vsphere_virtual_machine.EDB_SR_SETUP[0]]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts '${path.module}/utilities/scripts/configuremasterepas12.yml' --extra-vars='ip1=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} ip2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} ip3=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} EPASDBUSER=${local.DBUSEREPAS} REPLICATION_TYPE=${var.replication_type} DBPASSWORD=${local.DBPASS} MASTER=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}"

  }

}

resource "null_resource" "configureslave1" {
  triggers = {
    private_ip = "${join(",", vsphere_virtual_machine.EDB_SR_SETUP.*.default_ip_address)}"
  }

  depends_on = [null_resource.configuremaster]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='MASTER=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} SLAVE1=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} SLAVE2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password}  REPLICATION_TYPE=${var.replication_type}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}"

  }

}



resource "null_resource" "configureslave2" {
  triggers = {
    private_ip = "${join(",", vsphere_virtual_machine.EDB_SR_SETUP.*.default_ip_address)}"
  }

  depends_on = [null_resource.configuremaster]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='MASTER=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} SLAVE2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} SLAVE1=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} REPLICATION_USER_PASSWORD=${var.replication_password} REPLICATION_TYPE=${var.replication_type}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}"

  }

}


resource "null_resource" "efm_setup" {

  provisioner "local-exec" {

    command = "sleep 30"
  }

  depends_on = [
    null_resource.configuremaster,
    null_resource.configureslave2,
    null_resource.configureslave1,
    vsphere_virtual_machine.EDB_SR_SETUP[0],
    vsphere_virtual_machine.EDB_SR_SETUP[1],
    vsphere_virtual_machine.EDB_SR_SETUP[2]
  ]
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  '${path.module}/utilities/scripts/efm.yml' --extra-vars='MASTER=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} SLAVE1=${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address} SLAVE2=${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address} EFM_USER_PASSWORD=${var.efm_role_password} DBUSER=${local.DBUSEREPAS} NOTIFICATION_EMAIL=${var.notification_email_address}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address}"

  }

}


resource "vsphere_virtual_machine" "EDB_PEM_SERVER" {
  name                      = "Pemserver"
  resource_pool_id          = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id              = data.vsphere_datastore.datastore.id
  wait_for_guest_ip_timeout = -1
  num_cpus                  = local.CPUCORE_PEM
  memory                    = local.RAM_PEM
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

  depends_on = [null_resource.efm_setup]

  provisioner "local-exec" {
    command = "echo '${vsphere_virtual_machine.EDB_PEM_SERVER.default_ip_address} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    inline = [
      "yum info python"
    ]

    connection {
      host     = vsphere_virtual_machine.EDB_PEM_SERVER.default_ip_address
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      port     = "22"
      agent    = false
    }

  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  '${path.module}/utilities/scripts/pemserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PEM_IP=${vsphere_virtual_machine.EDB_PEM_SERVER.default_ip_address} DB_PASSWORD=${var.db_password_pem}' --limit ${vsphere_virtual_machine.EDB_PEM_SERVER.default_ip_address}"
  }


}

resource "null_resource" "configurepemagent" {

  provisioner "local-exec" {

    command = "sleep 30"
  }

  depends_on = [
    null_resource.configuremaster,
    null_resource.configureslave2,
    null_resource.configureslave1,
    vsphere_virtual_machine.EDB_PEM_SERVER,
    vsphere_virtual_machine.EDB_SR_SETUP[0],
    vsphere_virtual_machine.EDB_SR_SETUP[1],
    vsphere_virtual_machine.EDB_SR_SETUP[2],
    null_resource.efm_setup
  ]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${local.DBPASS} PEM_IP=${vsphere_virtual_machine.EDB_PEM_SERVER.default_ip_address} PEM_WEB_PASSWORD=${var.db_password_pem} DBUSER=${local.DBUSEREPAS}' --limit ${vsphere_virtual_machine.EDB_SR_SETUP[2].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[1].default_ip_address}"

  }

}

resource "vsphere_virtual_machine" "BART_SERVER" {
  name                      = "edb-bart-server"
  resource_pool_id          = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id              = data.vsphere_datastore.datastore.id
  wait_for_guest_ip_timeout = -1
  num_cpus                  = local.CPUCORE_BART
  memory                    = local.RAM_BART
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

  disk {
    label        = "disk1"
    unit_number  = 1
    size         = var.size
    datastore_id = data.vsphere_datastore.datastore.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  provisioner "local-exec" {
    command = "echo '${vsphere_virtual_machine.BART_SERVER.default_ip_address} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
  }


  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    inline = [
      "yum info python"
    ]

    connection {
      host     = vsphere_virtual_machine.BART_SERVER.default_ip_address
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      port     = "22"
      agent    = false
    }

  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  '${path.module}/utilities/scripts/bartserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_USER=${local.DBUSEREPAS} BART_IP=${vsphere_virtual_machine.BART_SERVER.default_ip_address} DB_IP=${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address} DB_ENGINE=epas12 DB_PASSWORD=${local.DBPASS} RETENTION_PERIOD=\"${var.retention_period}\"' --limit ${vsphere_virtual_machine.BART_SERVER.default_ip_address},${vsphere_virtual_machine.EDB_SR_SETUP[0].default_ip_address}"

  }

}



resource "null_resource" "remotehostfile" {

  provisioner "local-exec" {

    command = "rm -rf  ${path.module}/utilities/scripts/hosts"
  }

  depends_on = [
    null_resource.configuremaster,
    null_resource.configureslave2,
    null_resource.configureslave1,
    vsphere_virtual_machine.EDB_PEM_SERVER,
    null_resource.configurepemagent,
    vsphere_virtual_machine.EDB_SR_SETUP[0],
    vsphere_virtual_machine.EDB_SR_SETUP[1],
    vsphere_virtual_machine.EDB_SR_SETUP[2],
    null_resource.efm_setup
  ]
}
