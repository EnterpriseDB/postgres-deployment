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

module "security" {
  source = "./environment/security"

  vpc_id                   = var.vpc_id
  custom_security_group_id = var.custom_security_group_id
  sg_protocol              = var.sg_protocol
  public_cidr_block        = var.public_cidr_block
}

module "ec2" {
  source = "./environment/ec2"

  subnet_id                 = var.subnet_id
  instance_type             = var.instance_type
  iam_instance_profile      = var.iam_instance_profile
  ssh_keypair               = var.ssh_keypair
  custom_security_group_id  = var.custom_security_group_id
  created_by                = var.created_by
  cluster_name              = var.cluster_name
}
