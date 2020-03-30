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


data "aws_ami" "centos_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name = "description"
    
    values = [
      "CentOS Linux 7 x86_64 HVM EBS*"
    ]
 } 
 
  filter {
    name = "name"

    values = [
      "CentOS Linux 7 x86_64 HVM EBS *",
    ]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}



resource "aws_security_group" "edb_sg" {
    count = var.custom_security_group_id == "" ? 1 : 0 
    name = "edb_security_groupnewreplica"
    description = "Rule for edb-terraform-resource"
    vpc_id = var.vpc_id

    ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 5444
    to_port   = 5444
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 7800
    to_port   = 7900
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
}


resource "aws_instance" "EDB_Expand_DBCluster" {
   ami = data.aws_ami.centos_ami.id
   instance_type  = var.instance_type
   key_name   = data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair
   subnet_id = var.subnet_id
   iam_instance_profile = var.iam-instance-profile
   vpc_security_group_ids = ["${var.custom_security_group_id == "" ? aws_security_group.edb_sg[0].id : var.custom_security_group_id}"]
root_block_device {
   delete_on_termination = "true"
   volume_size = "8"
   volume_type = "gp2"
}

tags = {
  Name = "${local.CLUSTERNAME}-standby3"
  Created_By = "Terraform"
}


provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "local-exec" {
    command = "echo '${aws_instance.EDB_Expand_DBCluster.public_ip} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' > ${path.module}/utilities/scripts/hosts"
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = aws_instance.EDB_Expand_DBCluster.public_ip 
      type = "ssh"
      user = "centos"
      private_key = file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)
    }
  }

provisioner "local-exec" {
      command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' '${path.module}/utilities/scripts/install${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${aws_instance.EDB_Expand_DBCluster.public_ip}" 
}


lifecycle {
    create_before_destroy = true
  }

}

locals {
  DBUSERPG="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS="${var.db_user == "" || data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE == regexall("${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE}", "eaps10 epas11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  CLUSTERNAME="${data.terraform_remote_state.DB_CLUSTER.outputs.CLUSTER_NAME == "" ? data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE : data.terraform_remote_state.DB_CLUSTER.outputs.CLUSTER_NAME}"
}
######################################

## Addition of new node in replicaset begins here

#####################################


resource "null_resource" "configure_streaming_replication" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${aws_instance.EDB_Expand_DBCluster.id}"
  }

  depends_on = [aws_instance.EDB_Expand_DBCluster]

  provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
} 

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "echo '${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP} ansible_ssh_private_key_file=${data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path}' >> ${path.module}/utilities/scripts/hosts"
}



provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PrivateIP} ip2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PrivateIP} ip3=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PrivateIP} IPPRIVATE=${aws_instance.EDB_Expand_DBCluster.private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} REPLICATION_TYPE=${var.replication_type} MASTER=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} SLAVE1=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP} SLAVE2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP} NEWSLAVE=${aws_instance.EDB_Expand_DBCluster.public_ip} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} S3BUCKET=${data.terraform_remote_state.DB_CLUSTER.outputs.S3BUCKET}'" 

}

}

resource "null_resource" "configureefm" {

triggers = {
    cluster_instance_ids = "${aws_instance.EDB_Expand_DBCluster.id}"
  }

depends_on = [null_resource.configure_streaming_replication]

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/configureefm.yml --extra-vars='ip1=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PrivateIP} ip2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PrivateIP} ip3=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PrivateIP} EFM_USER_PASSWORD=${var.efm_role_password} MASTER_PUB_IP=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} REGION_NAME=${data.terraform_remote_state.DB_CLUSTER.outputs.Region} selfip=${aws_instance.EDB_Expand_DBCluster.private_ip} USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} NOTIFICATION_EMAIL=${var.notification_email_address} IPPRIVATE=${aws_instance.EDB_Expand_DBCluster.private_ip} SLAVE1=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP} SLAVE2=${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP} S3BUCKET=${data.terraform_remote_state.DB_CLUSTER.outputs.S3BUCKET} NEWSLAVE=${aws_instance.EDB_Expand_DBCluster.public_ip} MASTER=${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${aws_instance.EDB_Expand_DBCluster.public_ip},${data.terraform_remote_state.DB_CLUSTER.outputs.Master-PublicIP},${data.terraform_remote_state.DB_CLUSTER.outputs.Standby2-PublicIP},${data.terraform_remote_state.DB_CLUSTER.outputs.Standby1-PublicIP}"

}

}


resource "null_resource" "configurepemagent" {

triggers = { 
    path = "${path.root}/PEM_Server_AWS"
  }

depends_on = [ 
   aws_instance.EDB_Expand_DBCluster,
   null_resource.configureefm
]

provisioner "local-exec" {

   command = "sleep 30"
}

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(data.terraform_remote_state.DB_CLUSTER.outputs.Key-Pair-Path)}' ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${local.DBPASS} PEM_IP=${data.terraform_remote_state.PEM_SERVER.outputs.PEM_SERVER_IP} PEM_WEB_PASSWORD=${var.pem_web_ui_password} USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DB_ENGINE=${data.terraform_remote_state.DB_CLUSTER.outputs.DBENGINE} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${aws_instance.EDB_Expand_DBCluster.public_ip}"

}

}



resource "null_resource" "removehostfile" {

provisioner "local-exec" {
  command = "rm -rf ${path.module}/utilities/scripts/hosts"
}

depends_on = [
      null_resource.configurepemagent,
      null_resource.configureefm,
      null_resource.configure_streaming_replication,
      aws_instance.EDB_Expand_DBCluster
]
}

