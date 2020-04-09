variable "vpc_id" {}
variable "aws_public_subnet_1_id" {}
variable "aws_public_subnet_2_id" {}
variable "aws_public_subnet_3_id" {}
variable "project_tag" {}
variable "public_cidrblock" {}

resource "aws_internet_gateway" "edb-prereqs-postgres-igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = format("%s_%s", var.project_tag, "IGW")
  }
}

resource "aws_route_table" "edb-prereqs-postgres-customroutetable" {
  vpc_id = var.vpc_id

  route {
    // Associated subnet can reach everywhere, if set to 0.0.0.0
    cidr_block = var.public_cidrblock
    // Used to reach out to Internet
    gateway_id = aws_internet_gateway.edb-prereqs-postgres-igw.id
  }

  tags = {
    Name = format("%s_%s", var.project_tag, "CUSTOMROUTETABLE")
  }
}

resource "aws_route_table_association" "edb-prereqs-postgres-rtassociation-1" {
  subnet_id      = var.aws_public_subnet_1_id
  route_table_id = aws_route_table.edb-prereqs-postgres-customroutetable.id
}

resource "aws_route_table_association" "edb-prereqs-postgres-rtassociation-2" {
  subnet_id      = var.aws_public_subnet_2_id
  route_table_id = aws_route_table.edb-prereqs-postgres-customroutetable.id
}

resource "aws_route_table_association" "edb-prereqs-postgres-rtassociation-3" {
  subnet_id      = var.aws_public_subnet_3_id
  route_table_id = aws_route_table.edb-prereqs-postgres-customroutetable.id
}
