variable "postgres_count" {
  type = number
}
variable "bdr_count" {
  type = number
}
variable "bdr_witness_count" {
  type = number
}
variable "dbt2_client_count" {
  type = number
}
variable "dbt2_driver_count" {
  type = number
}
variable "hammerdb_count" {
  type = number
}
variable "pem_count" {
  type = number
}
variable "barman_count" {
  type = number
}
variable "pooler_count" {
  type = number
}
variable "vpc_id" {}
variable "project_tag" {}
variable "public_cidrblock" {}


data "aws_subnet_ids" "ids" {
  vpc_id = var.vpc_id
}

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

resource "aws_route_table_association" "edb-prereqs-postgres-rtassociations" {
  count = var.postgres_count + var.pem_count + var.barman_count + var.pooler_count + var.hammerdb_count + var.bdr_count + var.bdr_witness_count + var.dbt2_client_count + var.dbt2_driver_count

  subnet_id      = element(tolist(data.aws_subnet_ids.ids.ids), count.index)
  route_table_id = aws_route_table.edb-prereqs-postgres-customroutetable.id
}
