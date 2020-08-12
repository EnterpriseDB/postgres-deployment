variable "instance_count" {}
variable "vpc_id" {}
variable "instance_type" {}
variable "ssh_keypair" {}
variable "custom_security_group_id" {}
variable "cluster_name" {}
variable "created_by" {}


data "aws_subnet_ids" "ids" {
  vpc_id = var.vpc_id
}

resource "aws_instance" "EDB_DB_Cluster" {
  count = var.instance_count

  # CentOS
  ami = data.aws_ami.centos_ami.id
  # RHEL 7
  #ami           = data.aws_ami.rhel_ami.id

  instance_type          = var.instance_type
  key_name               = var.ssh_keypair
  subnet_id              = element(tolist(data.aws_subnet_ids.ids.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = "10"
    volume_type           = "gp2"
  }

  tags = {
    Name       = count.index == 0 ? format("%s-%s", var.cluster_name, "primary") : format("%s-%s%s", var.cluster_name, "standby", count.index)
    Created_By = var.created_by
  }

}

resource "aws_eip" "ip" {
  count    = var.instance_count
  instance = aws_instance.EDB_DB_Cluster[count.index].id
  vpc      = true
}

# EC2 AMI Instances
data "aws_ami" "rhel_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name = "name"

    values = [
      "RHEL-7.8-x86_64*"
    ]
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
