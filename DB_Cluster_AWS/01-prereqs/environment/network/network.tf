variable "vpc_id" {}
variable "public_subnet_1_cidrblock" {}
variable "public_subnet_2_cidrblock" {}
variable "public_subnet_3_cidrblock" {}
variable "public_subnet_tag" {}
variable "aws_region" {}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_1_cidrblock
  map_public_ip_on_launch = "true" //Makes the subnet public
  availability_zone       = format("%s%s", var.aws_region, "a")

  tags = {
    Name = format("%s_%s", var.public_subnet_tag, "1")
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_2_cidrblock
  map_public_ip_on_launch = "true" //Makes the subnet public
  availability_zone       = format("%s%s", var.aws_region, "b")

  tags = {
    Name = format("%s_%s", var.public_subnet_tag, "2")
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_3_cidrblock
  map_public_ip_on_launch = "true" //Makes the subnet public
  availability_zone       = format("%s%s", var.aws_region, "c")

  tags = {
    Name = format("%s_%s", var.public_subnet_tag, "3")
  }
}
