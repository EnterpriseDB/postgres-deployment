variable "subnet_id" {}
variable "iam_instance_profile" {}
variable "instance_type" {}
variable "ssh_keypair" {}
variable "ssh_key_path" {}
variable "custom_security_group_id" {}
variable "aws_security_group_edb_sg" {}
variable "db_engine" {}
variable "created_by" {}
variable "db_user" {}
variable "db_password" {}
variable "s3bucket" {}
variable "replication_type" {}
variable "replication_password" {}
variable "ssh_user" {}
variable "EDB_yumrepo_username" {}
variable "EDB_yumrepo_password" {}


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


resource "aws_instance" "EDB_DB_Cluster" {
  count                  = length(var.subnet_id)
  ami                    = data.aws_ami.centos_ami.id
  instance_type          = var.instance_type
  key_name               = var.ssh_keypair
  subnet_id              = var.subnet_id[count.index]
  iam_instance_profile   = var.iam_instance_profile
  vpc_security_group_ids = [var.custom_security_group_id == "" ? var.aws_security_group_edb_sg[0] : var.custom_security_group_id]


  root_block_device {
    delete_on_termination = "true"
    volume_size           = "8"
    volume_type           = "gp2"
  }

  tags = {
    Name       = count.index == 0 ? format("%s-%s", var.db_engine, "master") : format("%s-%s%s", var.db_engine, "slave", count.index)
    Created_By = var.created_by
  }


  provisioner "local-exec" {
    command = "echo '${self.public_ip} ansible_ssh_private_key_file=${var.ssh_key_path}' >> ${path.module}/../../utilities/scripts/hosts"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "remote-exec" {
    inline = [
      "yum info python"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_key_path)
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/../../utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/../../utilities/scripts/install${var.db_engine}.yml' --extra-vars='USER=${var.EDB_yumrepo_username} PASS=${var.EDB_yumrepo_password} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS}' --limit ${self.public_ip}"
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
    command = "echo '${aws_eip.master-ip.public_ip} ansible_ssh_private_key_file=${var.ssh_key_path}' >> ${path.module}/../../utilities/scripts/hosts"
  }
}


locals {
  DBUSERPG   = "${var.db_user == "" || var.db_engine == regexall("var.db_engine}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS = "${var.db_user == "" || var.db_engine == regexall("${var.db_engine}", "epas10 eaps11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS     = "${var.db_password == "" ? "postgres" : var.db_password}"
  REGION     = "${substr("${aws_instance.EDB_DB_Cluster[0].availability_zone}", 0, 9)}"
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
    command = "ansible-playbook -i ${path.module}/../../utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/../../utilities/scripts/configuremaster.yml' --extra-vars='ip1=${aws_instance.EDB_DB_Cluster[1].private_ip} ip2=${aws_instance.EDB_DB_Cluster[2].private_ip} ip3=${aws_instance.EDB_DB_Cluster[0].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.db_engine} PGDBUSER=${local.DBUSERPG}  EPASDBUSER=${local.DBUSEREPAS} REPLICATION_TYPE=${var.replication_type} DBPASSWORD=${local.DBPASS} S3BUCKET=${var.s3bucket}' --limit ${aws_eip.master-ip.public_ip}"

  }

}

resource "null_resource" "configureslave1" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

  depends_on = [null_resource.configuremaster]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/../../utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/../../utilities/scripts/configureslave.yml' --extra-vars='ip1=${aws_eip.master-ip.private_ip} ip2=${aws_instance.EDB_DB_Cluster[2].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.db_engine} REPLICATION_TYPE=${var.replication_type} SLAVE1=${aws_instance.EDB_DB_Cluster[1].public_ip} SLAVE2=${aws_instance.EDB_DB_Cluster[2].public_ip} MASTER=${aws_eip.master-ip.public_ip} S3BUCKET=${var.s3bucket}' --limit ${aws_instance.EDB_DB_Cluster[1].public_ip},${aws_eip.master-ip.public_ip}"

  }

}

resource "null_resource" "configureslave2" {
  # Define the trigger condition to run the resource block
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.EDB_DB_Cluster.*.id)}"
  }

  depends_on = [null_resource.configuremaster]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/../../utilities/scripts/hosts -u centos --private-key '${file(var.ssh_key_path)}' '${path.module}/../../utilities/scripts/configureslave.yml' --extra-vars='ip1=${aws_eip.master-ip.private_ip} ip2=${aws_instance.EDB_DB_Cluster[1].private_ip} REPLICATION_USER_PASSWORD=${var.replication_password} DB_ENGINE=${var.db_engine} REPLICATION_TYPE=${var.replication_type} SLAVE2=${aws_instance.EDB_DB_Cluster[2].public_ip} SLAVE1=${aws_instance.EDB_DB_Cluster[1].public_ip} MASTER=${aws_eip.master-ip.public_ip} S3BUCKET=${var.s3bucket}' --limit ${aws_instance.EDB_DB_Cluster[2].public_ip},${aws_eip.master-ip.public_ip}"

  }

}


resource "null_resource" "removehostfile" {

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/../../utilities/scripts/hosts"
  }

  depends_on = [
    null_resource.configureslave2,
    null_resource.configureslave1,
    null_resource.configuremaster,
    aws_instance.EDB_DB_Cluster
  ]
}
