variable "network_count" {
  type = number
}
variable "vpc_id" {}
variable "public_subnet_tag" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # AWS Availability Zones for us-west-1 are b and c so only two which amounts to 1
  az_count = length(data.aws_availability_zones.available.names)
}

resource "aws_subnet" "public_subnets" {
  count                   = var.network_count
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = "true" //Makes the subnet public
  availability_zone       = data.aws_availability_zones.available.names[count.index < local.az_count ? count.index : (local.az_count - 1)]

  tags = {
    Name = format("%s_%s", var.public_subnet_tag, count.index)
  }
}
