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
variable "pg_version" {}
variable "pg_password" {}
variable "postgres_server" {}
variable "rds_security_group_id" {}
variable "guc_effective_cache_size" {}
variable "guc_shared_buffers" {}
variable "guc_max_wal_size" {}

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

resource "aws_db_instance" "rds_server" {
  allocated_storage        = var.postgres_server["volume"]["size"]
  backup_retention_period  = 0
  db_subnet_group_name     = aws_db_subnet_group.rds.id
  engine                   = "postgres"
  engine_version           = var.pg_version
  identifier               = var.cluster_name
  instance_class           = var.postgres_server["instance_type"]
  multi_az                 = false
  name                     = var.cluster_name
  parameter_group_name     = aws_db_parameter_group.edb_rds_db_params.name
  password                 = var.pg_password
  port                     = 5432
  publicly_accessible      = true
  storage_encrypted        = false
  storage_type             = var.postgres_server["volume"]["type"]
  iops                     = var.postgres_server["volume"]["iops"]
  username                 = "postgres"
  vpc_security_group_ids   = [var.rds_security_group_id]
  skip_final_snapshot      = true

  tags = {
    Name       = format("%s-%s", var.cluster_name, "rds")
    Created_By = var.created_by
  }
}

resource "aws_db_parameter_group" "edb_rds_db_params" {
  name   = format("edb-%s", var.cluster_name)
  family = format("postgres%s", var.pg_version)

  parameter {
    apply_method = "pending-reboot"
    name         = "checkpoint_timeout"
    value        = "900"
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "effective_cache_size"
    value        = var.guc_effective_cache_size
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "max_connections"
    value        = "300"
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "max_wal_size"
    value        = var.guc_max_wal_size
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "random_page_cost"
    value        = "1.25"
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "shared_buffers"
    value        = var.guc_shared_buffers
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "work_mem"
    value        = "65536"
  }

  tags = {
    Name       = format("%s-%s", var.cluster_name, "rds")
    Created_By = var.created_by
  }
}
