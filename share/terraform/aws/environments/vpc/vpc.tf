variable "vpc_cidr_block" {}
variable "vpc_tag" {}


resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink   = false

  tags = {
    Name = var.vpc_tag
  }
}
