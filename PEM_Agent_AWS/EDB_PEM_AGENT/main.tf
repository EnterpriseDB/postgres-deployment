data "terraform_remote_state" "DB_CLUSTER" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster_AWS/terraform.tfstate"
  }
}

data "terraform_remote_state" "PEM_SERVER" {
  backend = "local"

  config = {
    path = "../${path.root}/PEM_Server_AWS/terraform.tfstate"
  }
}

locals {
  DBUSERPG="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"

}

resource "null_resource" "configurepemagent" {

triggers = { 
    path = "${path.root}/PEM_Server_AWS"
  }

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' > ${path.module}/utilities/scripts/hosts"
}  

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Slave1-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Slave2-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}


provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${var.db_password} PEM_IP=${data.terraform_remote_state.PEM_SERVER.outputs.PEM_SERVER_IP} PEM_WEB_PASSWORD=${var.pem_web_ui_password} USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}'"


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

