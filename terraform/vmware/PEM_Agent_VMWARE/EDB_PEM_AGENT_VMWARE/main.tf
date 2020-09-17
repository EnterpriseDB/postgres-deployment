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

locals {
  DBUSERPG   = "${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS = "${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"
}

resource "null_resource" "configurepemagent" {

  triggers = {
    path = "${path.root}/PEM_Server_VMWARE"
  }

  provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Master-IP} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' > ${path.module}/utilities/scripts/hosts"
  }

  provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-IP} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
  }

  provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-IP} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
  }


  provisioner "local-exec" {

    command = "sleep 30"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${var.db_password} PEM_IP=${data.terraform_remote_state.PEM_SERVER.outputs.PEM_SERVER_IP} PEM_WEB_PASSWORD=${var.pem_web_ui_password} USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}'"

  }

}

resource "null_resource" "removehostfile" {

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/utilities/scripts/hosts"
  }

  depends_on = [
    null_resource.configurepemagent
  ]
}

