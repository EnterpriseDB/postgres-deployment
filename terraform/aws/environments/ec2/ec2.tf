variable "os" {}
variable "ami_id" {}
variable "instance_count" {}
variable "pem_instance_count" {}
variable "synchronicity" {}
variable "vpc_id" {}
variable "instance_type" {}
variable "ansible_pem_inventory_yaml_filename" {}
variable "os_csv_filename" {}
variable "add_hosts_filename" {}
variable "ssh_key_path" {}
variable "custom_security_group_id" {}
variable "cluster_name" {}
variable "created_by" {}


data "aws_subnet_ids" "selected" {
  vpc_id = var.vpc_id
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.ssh_key_path
  public_key = file(var.ssh_key_path)
}

resource "aws_instance" "EDB_DB_Cluster" {
  count = var.instance_count

  ami = var.ami_id

  instance_type          = var.instance_type
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = "100"
    volume_type           = "gp2"
  }

  tags = {
    Name       = (var.pem_instance_count == "1" && count.index == 0 ? format("%s-%s", var.cluster_name, "pemserver") : (var.pem_instance_count == "0" && count.index == 1 ? format("%s-%s", var.cluster_name, "primary") : (count.index > 1 ? format("%s-%s%s", var.cluster_name, "standby", count.index) : format("%s-%s", var.cluster_name, "primary"))))
    Created_By = var.created_by
  }

  connection {
    #user = "ubuntu"
    private_key = file(var.ssh_key_path)
  }

}
