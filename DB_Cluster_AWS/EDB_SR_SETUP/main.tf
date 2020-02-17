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
  Name = count.index == 0 ? "${var.dbengine}-master" : "${var.dbengine}-slave${count.index}"
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
    command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/install${var.dbengine}.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${self.public_ip}" 
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
  DBUSERPG="${var.db_user == "" || var.dbengine == regexall("${var.dbengine}", "pg10 pg11 pg12") ? "postgres" : var.db_user}" 
  DBUSEREPAS="${var.db_user == "" || var.dbengine == regexall("${var.dbengine}", "epas10 eaps11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS="${var.db_password == "" ? "postgres" : var.db_password}"
  REGION="${substr("${aws_instance.EDB_DB_Cluster[0].availability_zone}", 0, 9)}"
}

#####################################
## Configuration of streaming replication start here
#
#
########################################### 


resource "null_resource" "configuremaster" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

depends_on = [aws_instance.EDB_DB_Cluster[0]]



provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/configuremaster.yml' --extra-vars='ip1=${aws_instance.EDB_DB_Cluster[1].private_ip} ip2=${aws_instance.EDB_DB_Cluster[2].private_ip} ip3=${aws_instance.EDB_DB_Cluster[0].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} REPLICATION_TYPE=${var.replication_type} DBPASSWORD=${local.DBPASS} S3BUCKET=${var.s3bucket}' --limit ${aws_eip.master-ip.public_ip}"

}

}

resource "null_resource" "configureslave1" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${aws_eip.master-ip.private_ip} ip2=${aws_instance.EDB_DB_Cluster[2].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} REPLICATION_TYPE=${var.replication_type} SELFIP1=${aws_instance.EDB_DB_Cluster[1].public_ip} SELFIP2=${aws_instance.EDB_DB_Cluster[2].public_ip} MASTER=${aws_eip.master-ip.public_ip} S3BUCKET=${var.s3bucket}' --limit ${aws_instance.EDB_DB_Cluster[1].public_ip},${aws_eip.master-ip.public_ip}"

}

}

resource "null_resource" "configureslave2" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

depends_on = [null_resource.configuremaster]

provisioner "local-exec" {
   command = "ansible-playbook -i ${path.module}/utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/utilities/scripts/configureslave.yml' --extra-vars='ip1=${aws_eip.master-ip.private_ip} ip2=${aws_instance.EDB_DB_Cluster[1].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.dbengine} REPLICATION_TYPE=${var.replication_type} SELFIP2=${aws_instance.EDB_DB_Cluster[2].public_ip} SELFIP1=${aws_instance.EDB_DB_Cluster[1].public_ip} MASTER=${aws_eip.master-ip.public_ip} S3BUCKET=${var.s3bucket}' --limit ${aws_instance.EDB_DB_Cluster[2].public_ip},${aws_eip.master-ip.public_ip}"

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
      aws_instance.EDB_DB_Cluster
]
}
