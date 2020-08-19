variable "instance_count" {}
variable "vpc_id" {}
variable "public_subnet_tag" {}
variable "aws_region" {}


data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  count                   = var.instance_count
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = "true" //Makes the subnet public
  availability_zone       = data.aws_availability_zones.available.names[count.index < 3 ? count.index : 2]

  tags = {
    Name = format("%s_%s", var.public_subnet_tag, "${count.index}")
  }
}
