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
  count         = length(var.subnet_id)
  ami           = data.aws_ami.centos_ami.id
  instance_type = var.instance_type
  #key_name               = aws_key_pair.generated_sshkey.key_name
  key_name               = var.ssh_keypair
  subnet_id              = var.subnet_id[count.index]
  iam_instance_profile   = var.iam_instance_profile
  vpc_security_group_ids = [var.custom_security_group_id]


  root_block_device {
    delete_on_termination = "true"
    volume_size           = "8"
    volume_type           = "gp2"
  }

  tags = {
    Name       = count.index == 0 ? format("%s-%s", var.db_engine, "master") : format("%s-%s%s", var.db_engine, "slave", count.index)
    Created_By = var.created_by
  }

}


resource "aws_eip" "master-ip" {
  instance = aws_instance.EDB_DB_Cluster[0].id
  vpc      = true
}


locals {
  DBUSERPG   = "${var.db_user == "" || var.db_engine == regexall("${var.db_engine}", "pg10 pg11 pg12") ? "postgres" : var.db_user}"
  DBUSEREPAS = "${var.db_user == "" || var.db_engine == regexall("${var.db_engine}", "epas10 eaps11 epas12") ? "enterprisedb" : var.db_user}"
  DBPASS     = "${var.db_password == "" ? "postgres" : var.db_password}"
  REGION     = "${substr("${aws_instance.EDB_DB_Cluster[0].availability_zone}", 0, 9)}"
}
