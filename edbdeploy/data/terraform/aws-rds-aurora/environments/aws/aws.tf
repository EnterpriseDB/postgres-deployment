variable "aws_ami_id" {}
variable "pem_server" {}
variable "hammerdb_server" {}
variable "vpc_id" {}
variable "ssh_user" {}
variable "ssh_pub_key" {}
variable "ssh_priv_key" {}
variable "custom_security_group_id" {}
variable "cluster_name" {}
variable "created_by" {}
variable "ansible_inventory_yaml_filename" {}
variable "add_hosts_filename" {}
variable "hammerdb" {}
variable "public_cidrblock" {}
variable "project_tag" {}
variable "rds_security_group_id" {}
variable "postgres_server" {}
variable "pg_version" {}
variable "pg_password" {}

data "aws_subnet_ids" "selected" {
  vpc_id = var.vpc_id
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.cluster_name
  public_key = file(var.ssh_pub_key)
}

resource "aws_instance" "hammerdb_server" {
  count = var.hammerdb_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.hammerdb_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.hammerdb_server["volume"]["size"]
    volume_type           = var.hammerdb_server["volume"]["type"]
    iops                  = var.hammerdb_server["volume"]["type"] == "io2" ?  var.hammerdb_server["volume"]["iops"] : var.hammerdb_server["volume"]["type"] == "io1" ? var.hammerdb_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "hammerdbserver", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_instance" "pem_server" {
  count = var.pem_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.pem_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.pem_server["volume"]["size"]
    volume_type           = var.pem_server["volume"]["type"]
    iops                  = var.pem_server["volume"]["type"] == "io2" ? var.pem_server["volume"]["iops"] : var.pem_server["volume"]["type"] == "io1" ? var.pem_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "pemserver", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = format("%s-%s", var.cluster_name, "rds-subset-group")
  subnet_ids = tolist(data.aws_subnet_ids.selected.ids)

  tags = {
    Name       = format("%s-%s", var.cluster_name, "rds-subset-group")
    Created_By = var.created_by
  }
}

resource "aws_rds_cluster" "rds_server" {
  cluster_identifier       = var.cluster_name
  database_name            = var.cluster_name
  engine                   = "aurora-postgresql"
  engine_version           = var.pg_version
  master_username          = "postgres"
  master_password          = var.pg_password
  backup_retention_period  = 1
  skip_final_snapshot      = true
  db_subnet_group_name     = "${aws_db_subnet_group.rds.name}"
  vpc_security_group_ids   = [var.custom_security_group_id]

  tags = {
    Name       = format("%s-%s", var.cluster_name, "rds-aurora-cluster")
    Created_By = var.created_by
  }
}

resource "aws_rds_cluster_instance" "rds_server" {
  count = 1

  identifier               = var.cluster_name
  cluster_identifier       = aws_rds_cluster.rds_server.id
  instance_class           = var.postgres_server["instance_type"]
  engine                   = "aurora-postgresql"
  engine_version           = var.pg_version
  publicly_accessible      = true
  apply_immediately        = true

  tags = {
    Name       = format("%s-%s", var.cluster_name, "rds-aurora-instance")
    Created_By = var.created_by
  }
}
