variable vpc_id {}
variable custom_security_group_id {}
variable sg_protocol {}
variable public_cidr_block {}

resource "aws_security_group" "edb_sg" {
  count       = var.custom_security_group_id == "" ? 1 : 0
  name        = "edb_security_groupforsr"
  description = "Rule for edb-terraform-resource"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = var.sg_protocol
    cidr_blocks = [var.public_cidr_block]
  }
  ingress {
    from_port   = 5444
    to_port     = 5444
    protocol    = var.sg_protocol
    cidr_blocks = [var.public_cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = var.sg_protocol
    cidr_blocks = [var.public_cidr_block]
  }

  ingress {
    from_port   = 7800
    to_port     = 7900
    protocol    = var.sg_protocol
    cidr_blocks = [var.public_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_cidr_block]
  }

}
