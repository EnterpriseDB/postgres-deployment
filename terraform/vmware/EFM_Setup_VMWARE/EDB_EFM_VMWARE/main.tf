data "terraform_remote_state" "SR" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster_VMWARE/terraform.tfstate"
  }
}

locals {
  DBUSERPG="${var.db_user == "" || data.terraform_remote_state.SR.outputs.DBENGINE == regexall("${data.terraform_remote_state.SR.outputs.DBENGINE}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS="${var.db_user == "" || data.terraform_remote_state.SR.outputs.DBENGINE == regexall("${data.terraform_remote_state.SR.outputs.DBENGINE}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"

}

resource "null_resource" "master" {

triggers = { 
    path = "${path.root}/DB_Cluster_VMWARE"
  }

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Master-IP} ansible_user=${data.terraform_remote_state.SR.outputs.SSH-USER} ansible_ssh_pass=${var.ssh_password}' > ${path.module}/utilities/scripts/hosts"
}  

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Standby1-IP} ansible_user=${data.terraform_remote_state.SR.outputs.SSH-USER} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Standby2-IP} ansible_user=${data.terraform_remote_state.SR.outputs.SSH-USER} ansible_ssh_pass=${var.ssh_password}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {

   command = "sleep 30"
}


provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts ${path.module}/utilities/scripts/configuremaster.yml --extra-vars='ip1=${data.terraform_remote_state.SR.outputs.Master-IP} ip2=${data.terraform_remote_state.SR.outputs.Standby1-IP} ip3=${data.terraform_remote_state.SR.outputs.Standby2-IP} EFM_USER_PASSWORD=${var.efm_role_password}  USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${data.terraform_remote_state.SR.outputs.Master-IP}"

}

}

resource "null_resource" "slave1" {

triggers = {
    path = "${path.root}/DB_Cluster_VMWARE"
  }

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts  ${path.module}/utilities/scripts/configureslave.yml --extra-vars='ip1=${data.terraform_remote_state.SR.outputs.Master-IP} ip2=${data.terraform_remote_state.SR.outputs.Standby1-IP} ip3=${data.terraform_remote_state.SR.outputs.Standby2-IP} EFM_USER_PASSWORD=${var.efm_role_password} selfip=${data.terraform_remote_state.SR.outputs.Standby1-IP} USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${data.terraform_remote_state.SR.outputs.Standby1-IP}"

}

}

resource "null_resource" "slave2" {

triggers = {
    path = "${path.root}/DB_Cluster_VMWARE"
  }

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts ${path.module}/utilities/scripts/configureslave.yml --extra-vars='ip1=${data.terraform_remote_state.SR.outputs.Master-IP} ip2=${data.terraform_remote_state.SR.outputs.Standby1-IP} ip3=${data.terraform_remote_state.SR.outputs.Standby2-IP} EFM_USER_PASSWORD=${var.efm_role_password} selfip=${data.terraform_remote_state.SR.outputs.Standby2-IP} USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${data.terraform_remote_state.SR.outputs.Standby2-IP}"

}

}

resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
      null_resource.slave2,
      null_resource.slave1,
      null_resource.master
]
}

