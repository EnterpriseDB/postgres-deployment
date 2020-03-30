data "terraform_remote_state" "SR" {
  backend = "local"

  config = {
    path = "../${path.root}/DB_Cluster_AWS/terraform.tfstate"
  }
}

locals {
  DBUSERPG="${var.db_user == "" || data.terraform_remote_state.SR.outputs.DBENGINE == regexall("${data.terraform_remote_state.SR.outputs.DBENGINE}", "pg10 pg11 pg12")  ? "postgres" : var.db_user}"
  DBUSEREPAS="${var.db_user == "" || data.terraform_remote_state.SR.outputs.DBENGINE == regexall("${data.terraform_remote_state.SR.outputs.DBENGINE}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"

}

resource "null_resource" "master" {

triggers = { 
    path = "${path.root}/DB_Cluster_AWS"
  }

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Master-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.SR.outputs.Key-Pair-Path}' > ${path.module}/utilities/scripts/hosts"
}  

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Standby1-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.SR.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.SR.outputs.Standby2-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.SR.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.SR.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/configuremaster.yml --extra-vars='ip1=${data.terraform_remote_state.SR.outputs.Master-PrivateIP} ip2=${data.terraform_remote_state.SR.outputs.Standby1-PrivateIP} ip3=${data.terraform_remote_state.SR.outputs.Standby2-PrivateIP} EFM_USER_PASSWORD=${var.efm_role_password} MASTER_PUB_IP=${data.terraform_remote_state.SR.outputs.Master-PublicIP} REGION_NAME=${data.terraform_remote_state.SR.outputs.Region} USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} S3BUCKET=${data.terraform_remote_state.SR.outputs.S3BUCKET}' --limit ${data.terraform_remote_state.SR.outputs.Master-PublicIP}"

}

}

resource "null_resource" "slave1" {

triggers = {
    path = "${path.root}/DB_Cluster_AWS"
  }

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.SR.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/configureslave.yml --extra-vars='ip1=${data.terraform_remote_state.SR.outputs.Master-PrivateIP} ip2=${data.terraform_remote_state.SR.outputs.Standby1-PrivateIP} ip3=${data.terraform_remote_state.SR.outputs.Standby2-PrivateIP} EFM_USER_PASSWORD=${var.efm_role_password} MASTER_PUB_IP=${data.terraform_remote_state.SR.outputs.Master-PublicIP} REGION_NAME=${data.terraform_remote_state.SR.outputs.Region} selfip=${data.terraform_remote_state.SR.outputs.Standby1-PrivateIP} USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE}  NOTIFICATION_EMAIL=${var.notification_email_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} S3BUCKET=${data.terraform_remote_state.SR.outputs.S3BUCKET}' --limit ${data.terraform_remote_state.SR.outputs.Standby1-PublicIP}"

}

}

resource "null_resource" "slave2" {

triggers = {
    path = "${path.root}/DB_Cluster_AWS"
  }

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.SR.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/configureslave.yml --extra-vars='ip1=${data.terraform_remote_state.SR.outputs.Master-PrivateIP} ip2=${data.terraform_remote_state.SR.outputs.Standby1-PrivateIP} ip3=${data.terraform_remote_state.SR.outputs.Standby2-PrivateIP} EFM_USER_PASSWORD=${var.efm_role_password} MASTER_PUB_IP=${data.terraform_remote_state.SR.outputs.Master-PublicIP} REGION_NAME=${data.terraform_remote_state.SR.outputs.Region} selfip=${data.terraform_remote_state.SR.outputs.Standby2-PrivateIP} USER=${var.EDB_Yum_Repo_Username} PASS=${var.EDB_Yum_Repo_Password} DB_ENGINE=${data.terraform_remote_state.SR.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} S3BUCKET=${data.terraform_remote_state.SR.outputs.S3BUCKET}' --limit ${data.terraform_remote_state.SR.outputs.Standby2-PublicIP}"

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

