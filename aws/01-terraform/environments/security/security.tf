variable "vpc_id" {}
variable "public_cidrblock" {}
variable "project_tag" {}

resource "aws_security_group" "edb-prereqs-rules" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.public_cidrblock]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    // This means, all ip address are allowed to ssh ! 
    // Not recommended for production. 
    // Limit IP Addresses in a Production Environment !
    cidr_blocks = [var.public_cidrblock]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.public_cidrblock]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.public_cidrblock]
  }
  ingress {
    from_port   = 5444
    to_port     = 5444
    protocol    = "tcp"
    cidr_blocks = [var.public_cidrblock]
  }

  ingress {
    from_port   = 7800
    to_port     = 7810
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s_%s", var.project_tag, "SSH_ALLOWED")
  }
}
