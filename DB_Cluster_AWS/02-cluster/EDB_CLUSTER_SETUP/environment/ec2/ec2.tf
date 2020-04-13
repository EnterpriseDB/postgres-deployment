variable "subnet_id" {}
variable "iam_instance_profile" {}
variable "instance_type" {}
variable "ssh_keypair" {}
variable "custom_security_group_id" {}
variable "db_engine" {}
variable "created_by" {}


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
