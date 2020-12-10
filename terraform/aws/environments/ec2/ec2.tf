variable "os" {}
variable "ami_id" {}
variable "instance_count" {}
variable "pem_instance_count" {}
variable "synchronicity" {}
variable "vpc_id" {}
variable "instance_type" {}
variable "instance_volume_type" {}
variable "instance_volume_iops" {}
variable "instance_volume_size" {}
variable "ebs_volume_count" {}
variable "ebs_volume_type" {}
variable "ebs_volume_size" {}
variable "ebs_volume_iops" {}
variable "ebs_volume_encryption" {}
variable "ansible_pem_inventory_yaml_filename" {}
variable "os_csv_filename" {}
variable "add_hosts_filename" {}
variable "ssh_key_path" {}
variable "full_private_ssh_key_path" {}
variable "custom_security_group_id" {}
variable "cluster_name" {}
variable "root_user" {}
variable "created_by" {}


locals {
  lnx_ebs_device_names = ["/dev/sdf",
    "/dev/sdg",
    "/dev/sdh",
    "/dev/sdi",
    "/dev/sdj"
  ]
}

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
    volume_size           = var.instance_volume_size
    volume_type           = var.instance_volume_type
    iops                  = var.instance_volume_type == "io2" ? var.instance_volume_iops : var.instance_volume_type == "io1" ? var.instance_volume_iops : null
  }

  tags = {
    Name       = (var.pem_instance_count == "1" && count.index == 0 ? format("%s-%s", var.cluster_name, "pemserver") : (var.pem_instance_count == "0" && count.index == 1 ? format("%s-%s", var.cluster_name, "primary") : (count.index > 1 ? format("%s-%s%s", var.cluster_name, "standby", count.index) : format("%s-%s", var.cluster_name, "primary"))))
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_key_path)
  }

}

resource "aws_ebs_volume" "ebs-vol" {
  count = var.instance_count * var.ebs_volume_count

  availability_zone = element(aws_instance.EDB_DB_Cluster.*.availability_zone, count.index)
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  iops              = var.ebs_volume_type == "io2" ? var.ebs_volume_iops : var.ebs_volume_type == "io1" ? var.ebs_volume_iops : null
  encrypted         = var.ebs_volume_encryption

  tags = {
    Name = format("%s-%s-%s", var.cluster_name, "ebs", count.index)
  }
}

resource "aws_volume_attachment" "attached-vol" {
  count = var.instance_count * var.ebs_volume_count

  device_name = element(local.lnx_ebs_device_names, count.index)
  volume_id   = aws_ebs_volume.ebs-vol.*.id[count.index]
  instance_id = element(aws_instance.EDB_DB_Cluster.*.id, count.index)

  provisioner "remote-exec" {
    script = "../../terraform/aws/environments/ec2/setup_volumes.sh"

    connection {
      type        = "ssh"
      user        = var.root_user
      host        = element(aws_instance.EDB_DB_Cluster.*.public_ip, floor(count.index / length(var.ebs_volume_count)))
      private_key = file(var.full_private_ssh_key_path)
    }
  }
}
