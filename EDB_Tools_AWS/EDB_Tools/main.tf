data "aws_ami" "centos_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

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
    name = "edb_security_groupforsr"
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


resource "aws_instance" "EDB_DB_Cluster" {
   count = length(var.subnet_id)
   ami = data.aws_ami.centos_ami.id
   instance_type  = var.instance_type
   key_name   = var.ssh_keypair
   subnet_id = var.subnet_id[count.index]
   iam_instance_profile = var.iam-instance-profile
   vpc_security_group_ids = ["${var.custom_security_group_id == "" ? aws_security_group.edb_sg[0].id : var.custom_security_group_id}"]
root_block_device {
   delete_on_termination = "true"
   volume_size = "8"
   volume_type = "gp2"
}

tags = {
  Name = count.index == 0 ? "${local.CLUSTERNAME}-master" : "${local.CLUSTERNAME}-standby${count.index}"
  Created_By = "Terraform"
}

provisioner "local-exec" {
    command = "echo '${self.public_ip} ansible_ssh_private_key_file=${var.ssh_key_path}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = self.public_ip 
      type = "ssh"
      user = var.ssh_user
      private_key = file(var.ssh_key_path)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/installepas12.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} DBUSER=${local.DBUSEREPAS}' --limit ${self.public_ip}" 
}

lifecycle {
    create_before_destroy = true
  }

}

resource "aws_eip" "master-ip" {
    instance = aws_instance.EDB_DB_Cluster[0].id
    vpc      = true

depends_on = [aws_instance.EDB_DB_Cluster[0]]

provisioner "local-exec" {
    command = "echo '${aws_eip.master-ip.public_ip} ansible_ssh_private_key_file=${var.ssh_key_path}' >> ${path.module}/utilities/scripts/hosts"
}
}


locals {
  DBUSEREPAS="${var.db_user == ""  ? "enterprisedb" : var.db_user}"
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  REGION="${substr("${aws_instance.EDB_DB_Cluster[0].availability_zone}", 0, 9)}"
  CLUSTERNAME="${var.cluster_name == "" ? "epas12" : var.cluster_name}"  
}

#####################################
## Configuration of streaming replication start here
#
########################################### 


resource "null_resource" "configuremaster" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

depends_on = [aws_instance.EDB_DB_Cluster[0]]



provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/configuremasterepas12.yml' --extra-vars='ip1=${aws_instance.EDB_DB_Cluster[1].private_ip} ip2=${aws_instance.EDB_DB_Cluster[2].private_ip} ip3=${aws_instance.EDB_DB_Cluster[0].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} EPASDBUSER=${local.DBUSEREPAS} REPLICATION_TYPE=${var.replication_type} DBPASSWORD=${local.DBPASS} S3BUCKET=${var.s3bucket}' --limit ${aws_eip.master-ip.public_ip}"

}

}

resource "null_resource" "configureslave1" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${aws_eip.master-ip.private_ip} ip2=${aws_instance.EDB_DB_Cluster[2].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password}  REPLICATION_TYPE=${var.replication_type} SLAVE1=${aws_instance.EDB_DB_Cluster[1].public_ip} SLAVE2=${aws_instance.EDB_DB_Cluster[2].public_ip} MASTER=${aws_eip.master-ip.public_ip} S3BUCKET=${var.s3bucket}' --limit ${aws_instance.EDB_DB_Cluster[1].public_ip},${aws_eip.master-ip.public_ip}"

}

}

resource "null_resource" "configureslave2" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${aws_eip.master-ip.private_ip} ip2=${aws_instance.EDB_DB_Cluster[1].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} REPLICATION_TYPE=${var.replication_type} SLAVE2=${aws_instance.EDB_DB_Cluster[2].public_ip} SLAVE1=${aws_instance.EDB_DB_Cluster[1].public_ip} MASTER=${aws_eip.master-ip.public_ip} S3BUCKET=${var.s3bucket}' --limit ${aws_instance.EDB_DB_Cluster[2].public_ip},${aws_eip.master-ip.public_ip}"

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
        aws_instance.EDB_DB_Cluster[0],
        aws_instance.EDB_DB_Cluster[1],
        aws_instance.EDB_DB_Cluster[2]
]
provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' ${path.module}/utilities/scripts/efm.yml --extra-vars='ip1=${aws_eip.master-ip.private_ip} ip2=${aws_instance.EDB_DB_Cluster[1].private_ip} ip3=${aws_instance.EDB_DB_Cluster[2].private_ip} EFM_USER_PASSWORD=${var.efm_role_password} MASTER=${aws_eip.master-ip.public_ip} REGION_NAME=${local.REGION} NOTIFICATION_EMAIL=${var.notification_email_address} DBUSER=${local.DBUSEREPAS}  S3BUCKET=${var.s3bucket} SLAVE2=${aws_instance.EDB_DB_Cluster[2].public_ip} SLAVE1=${aws_instance.EDB_DB_Cluster[1].public_ip}' --limit ${aws_eip.master-ip.public_ip},${aws_instance.EDB_DB_Cluster[1].public_ip},${aws_instance.EDB_DB_Cluster[2].public_ip}"

}

}

resource "aws_security_group" "edb_pem_sg" {
    name = "edb_pemsecurity_group"
    count = var.custom_security_group_id_pem == "" ? 1 : 0
    description = "Rule for edb-terraform-resource"
    vpc_id = var.vpc_id

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
    from_port = 8443
    to_port   = 8443
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


resource "aws_instance" "EDB_Pem_Server" {
   ami = data.aws_ami.centos_ami.id
   instance_type  = var.instance_type_pem
   key_name   = var.ssh_keypair_pem
   subnet_id = var.subnet_id_pem
   vpc_security_group_ids =  ["${var.custom_security_group_id_pem == "" ? aws_security_group.edb_pem_sg[0].id : var.custom_security_group_id_pem}"]
root_block_device {
   delete_on_termination = "true"
   volume_size = "8"
   volume_type = "gp2"
}

depends_on = [null_resource.efm_setup]

tags = {
  Name = "edb-pem-server"
  Created_By = "Terraform"
}

provisioner "local-exec" {
    command = "echo '${aws_instance.EDB_Pem_Server.public_ip} ansible_ssh_private_key_file=${var.ssh_key_path_pem}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = aws_instance.EDB_Pem_Server.public_ip 
      type = "ssh"
      user = "centos"
      private_key = file(var.ssh_key_path_pem)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path_pem)}' '${path.module}/utilities/scripts/pemserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PEM_IP=${aws_instance.EDB_Pem_Server.public_ip} DB_PASSWORD=${var.db_password_pem}' --limit ${aws_instance.EDB_Pem_Server.public_ip}" 
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
        aws_instance.EDB_Pem_Server,
        aws_instance.EDB_DB_Cluster[0],
        aws_instance.EDB_DB_Cluster[1],
        aws_instance.EDB_DB_Cluster[2],
        null_resource.efm_setup
]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' ${path.module}/utilities/scripts/installpemagent.yml --extra-vars='DBPASSWORD=${local.DBPASS} PEM_IP=${aws_instance.EDB_Pem_Server.public_ip} PEM_WEB_PASSWORD=${var.db_password_pem} DBUSER=${local.DBUSEREPAS}' --limit ${aws_eip.master-ip.public_ip},${aws_instance.EDB_DB_Cluster[1].public_ip},${aws_instance.EDB_DB_Cluster[2].public_ip}" 

}

}

resource "aws_security_group" "edb_bart_sg" {
    count = var.custom_security_group_id_bart == "" ? 1 : 0 
    name = "edb_bartsecurity_group"
    description = "Rule for edb-terraform-resource"
    vpc_id = var.vpc_id

    ingress {
    from_port = 22
    to_port   = 22
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


resource "aws_instance" "EDB_Bart_Server" {
   ami = data.aws_ami.centos_ami.id
   instance_type  = var.instance_type_bart
   key_name   = var.ssh_keypair_bart
   subnet_id = var.subnet_id_bart
   vpc_security_group_ids = ["${var.custom_security_group_id_bart == "" ? aws_security_group.edb_bart_sg[0].id : var.custom_security_group_id_bart}"]
root_block_device {
   delete_on_termination = "true"
   volume_size = "8"
   volume_type = "gp2"
}
ebs_block_device {
  delete_on_termination = "true"
  device_name = "/dev/sdf"
  volume_size = var.size
  volume_type = "gp2" 
}

tags = {
  Name = "edb-bart-server"
  Created_By = "Terraform"
}



provisioner "local-exec" {
    command = "echo '${aws_instance.EDB_Bart_Server.public_ip} ansible_ssh_private_key_file=${var.ssh_key_path_bart}' >> ${path.module}/utilities/scripts/hosts"
}

provisioner "local-exec" {
    command = "sleep 60" 
}

provisioner "remote-exec" {
    inline = [
     "yum info python"
]
connection {
      host = aws_instance.EDB_Bart_Server.public_ip 
      type = "ssh"
      user = "centos"
      private_key = file(var.ssh_key_path_bart)
    }
  }

provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path_bart)}' '${path.module}/utilities/scripts/bartserver.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} BART_IP=${aws_instance.EDB_Bart_Server.public_ip} DB_IP=${aws_eip.master-ip.public_ip} DB_ENGINE=epas12 DB_PASSWORD=${local.DBPASS} DB_USER=${local.DBUSEREPAS} RETENTION_PERIOD=\"${var.retention_period}\"' --limit ${aws_instance.EDB_Bart_Server.public_ip},${aws_eip.master-ip.public_ip}" 
}

depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        aws_instance.EDB_Pem_Server,
        aws_instance.EDB_DB_Cluster[0],
        aws_instance.EDB_DB_Cluster[1],
        aws_instance.EDB_DB_Cluster[2],
        null_resource.efm_setup,
        null_resource.configurepemagent
]


}


resource "null_resource" "remotehostfile" {

provisioner "local-exec" {

   command = "rm -rf  ${path.module}/utilities/scripts/hosts"
}

depends_on = [
        null_resource.configuremaster,
        null_resource.configureslave2,
        null_resource.configureslave1,
        aws_instance.EDB_Pem_Server,
        null_resource.configurepemagent,
        aws_instance.EDB_DB_Cluster[0],
        aws_instance.EDB_DB_Cluster[1],
        aws_instance.EDB_DB_Cluster[2],
        aws_instance.EDB_Bart_Server
]
}

