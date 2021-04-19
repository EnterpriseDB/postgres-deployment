variable "aws_ami_id" {}
variable "pem_server" {}
variable "postgres_server" {}
variable "barman_server" {}
variable "pooler_server" {}
variable "hammerdb_server" {}
variable "replication_type" {}
variable "vpc_id" {}
variable "ssh_user" {}
variable "ssh_pub_key" {}
variable "ssh_priv_key" {}
variable "custom_security_group_id" {}
variable "cluster_name" {}
variable "created_by" {}
variable "ansible_inventory_yaml_filename" {}
variable "add_hosts_filename" {}
variable "barman" {}
variable "pooler_type" {}
variable "pooler_local" {}
variable "hammerdb" {}

locals {
  lnx_ebs_device_names = [
    "/dev/sdf",
    "/dev/sdg",
    "/dev/sdh",
    "/dev/sdi",
    "/dev/sdj"
  ]
}

locals {
  postgres_mount_points = [
    "/pgdata",
    "/pgwal",
    "/pgtblspc1",
    "/pgtblspc2",
    "/pgtblspc3"
  ]
}

locals {
  lnx_nvme_device_names = [
    "/dev/nvme1n1",
    "/dev/nvme2n1",
    "/dev/nvme3n1",
    "/dev/nvme4n1",
    "/dev/nvme5n1",
  ]
}

locals {
  barman_mount_points = [
    "/var/lib/barman"
  ]
}

data "aws_subnet_ids" "selected" {
  vpc_id = var.vpc_id
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.cluster_name
  public_key = file(var.ssh_pub_key)
}

resource "aws_instance" "postgres_server" {
  count = var.postgres_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.postgres_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.postgres_server["volume"]["size"]
    volume_type           = var.postgres_server["volume"]["type"]
    iops                  = var.postgres_server["volume"]["type"] == "io2" ? var.postgres_server["volume"]["iops"] : var.postgres_server["volume"]["type"] == "io1" ? var.postgres_server["volume"]["iops"] : null
  }

  tags = {
    Name       = (count.index == 0 ? format("%s-%s", var.cluster_name, "primary") : format("%s-%s%s", var.cluster_name, "standby", count.index))
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_ebs_volume" "postgres_ebs_vol" {
  count = var.postgres_server["count"] * var.postgres_server["additional_volumes"]["count"]

  availability_zone = element(aws_instance.postgres_server.*.availability_zone, count.index)
  size              = var.postgres_server["additional_volumes"]["size"]
  type              = var.postgres_server["additional_volumes"]["type"]
  iops              = var.postgres_server["additional_volumes"]["type"] == "io2" ? var.postgres_server["additional_volumes"]["iops"] : var.postgres_server["additional_volumes"]["type"] == "io1" ? var.postgres_server["additional_volumes"]["iops"] : null
  encrypted         = var.postgres_server["additional_volumes"]["encrypted"]

  tags = {
    Name = format("pg-%s-%s-%s", var.cluster_name, "ebs", count.index)
  }
}

resource "null_resource" "postgres_copy_setup_volume_script" {
  count = var.postgres_server["count"]

  depends_on = [
    aws_instance.postgres_server,
    aws_volume_attachment.postgres_attached_vol
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/setup_volume.sh")
    destination = "/tmp/setup_volume.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.postgres_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}


resource "aws_volume_attachment" "postgres_attached_vol" {
  count = var.postgres_server["count"] * var.postgres_server["additional_volumes"]["count"]

  device_name = element(local.lnx_ebs_device_names, floor(count.index / var.postgres_server["count"]))
  volume_id   = aws_ebs_volume.postgres_ebs_vol.*.id[count.index]
  instance_id = element(aws_instance.postgres_server.*.id, count.index)
}

resource "null_resource" "postgres_setup_volume" {
  count = var.postgres_server["count"] * var.postgres_server["additional_volumes"]["count"]

  depends_on = [
    null_resource.postgres_copy_setup_volume_script
  ]

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /tmp/setup_volume.sh",
        "/tmp/setup_volume.sh ${element(local.lnx_nvme_device_names, floor(count.index / var.postgres_server["count"]))} ${element(local.postgres_mount_points, floor(count.index / var.postgres_server["count"]))} >> /tmp/mount.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.postgres_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
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

resource "aws_instance" "barman_server" {
  count = var.barman_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.barman_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.barman_server["volume"]["size"]
    volume_type           = var.barman_server["volume"]["type"]
    iops                  = var.barman_server["volume"]["type"] == "io2" ? var.barman_server["volume"]["iops"] : var.barman_server["volume"]["type"] == "io1" ? var.barman_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "barman", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "aws_ebs_volume" "barman_ebs_vol" {
  count = var.barman_server["count"] * var.barman_server["additional_volumes"]["count"]

  availability_zone = element(aws_instance.barman_server.*.availability_zone, count.index)
  size              = var.barman_server["additional_volumes"]["size"]
  type              = var.barman_server["additional_volumes"]["type"]
  iops              = var.barman_server["additional_volumes"]["type"] == "io2" ? var.barman_server["additional_volumes"]["iops"] : var.barman_server["additional_volumes"]["type"] == "io1" ? var.barman_server["additional_volumes"]["iops"] : null
  encrypted         = var.barman_server["additional_volumes"]["encrypted"]

  tags = {
    Name = format("barman-%s-%s-%s", var.cluster_name, "ebs", count.index)
  }
}

resource "aws_volume_attachment" "barman_attached_vol" {
  count = var.barman_server["count"] * var.barman_server["additional_volumes"]["count"]

  device_name = element(local.lnx_ebs_device_names, count.index)
  volume_id   = aws_ebs_volume.barman_ebs_vol.*.id[count.index]
  instance_id = element(aws_instance.barman_server.*.id, count.index)
}

resource "null_resource" "barman_copy_setup_volume_script" {
  count = var.barman_server["count"]

  depends_on = [
    aws_instance.barman_server,
    aws_volume_attachment.barman_attached_vol
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/setup_volume.sh")
    destination = "/tmp/setup_volume.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.barman_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "barman_setup_volume" {
  count = var.barman_server["count"] * var.barman_server["additional_volumes"]["count"]

  depends_on = [
    null_resource.barman_copy_setup_volume_script
  ]

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /tmp/setup_volume.sh",
        "/tmp/setup_volume.sh ${element(local.lnx_nvme_device_names, floor(count.index / var.barman_server["count"]))} ${element(local.barman_mount_points, floor(count.index / var.barman_server["count"]))} >> /tmp/mount.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.barman_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "aws_instance" "pooler_server" {
  count = var.pooler_server["count"]

  ami = var.aws_ami_id

  instance_type          = var.pooler_server["instance_type"]
  key_name               = aws_key_pair.key_pair.id
  subnet_id              = element(tolist(data.aws_subnet_ids.selected.ids), count.index)
  vpc_security_group_ids = [var.custom_security_group_id]

  root_block_device {
    delete_on_termination = "true"
    volume_size           = var.pooler_server["volume"]["size"]
    volume_type           = var.pooler_server["volume"]["type"]
    iops                  = var.pooler_server["volume"]["type"] == "io2" ? var.pooler_server["volume"]["iops"] : var.pooler_server["volume"]["type"] == "io1" ? var.pooler_server["volume"]["iops"] : null
  }

  tags = {
    Name       = format("%s-%s%s", var.cluster_name, "pooler", count.index + 1)
    Created_By = var.created_by
  }

  connection {
    private_key = file(var.ssh_pub_key)
  }
}

resource "null_resource" "pem_copy_hostname_script" {
  count = var.pem_server["count"]

  depends_on = [
    aws_instance.pem_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_ips_to_hosts.sh")
    destination = "/tmp/add_ips_to_hosts.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.pem_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "pem_copy_nickname_script" {
  count = var.pem_server["count"]

  depends_on = [
    aws_instance.pem_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_nickname_to_shell.sh")
    destination = "/tmp/add_nickname_to_shell.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.pem_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "postgres_copy_hostname_script" {
  count = var.postgres_server["count"]

  depends_on = [
    aws_instance.postgres_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_ips_to_hosts.sh")
    destination = "/tmp/add_ips_to_hosts.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.postgres_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "postgres_copy_nickname_script" {
  count = var.postgres_server["count"]

  depends_on = [
    aws_instance.postgres_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_nickname_to_shell.sh")
    destination = "/tmp/add_nickname_to_shell.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.postgres_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "barman_copy_hostname_script" {
  count = var.barman_server["count"]

  depends_on = [
    aws_instance.barman_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_ips_to_hosts.sh")
    destination = "/tmp/add_ips_to_hosts.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.barman_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "barman_copy_nickname_script" {
  count = var.barman_server["count"]

  depends_on = [
    aws_instance.barman_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_nickname_to_shell.sh")
    destination = "/tmp/add_nickname_to_shell.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.barman_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "pooler_copy_hostname_script" {
  count = var.pooler_server["count"]

  depends_on = [
    aws_instance.pooler_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_ips_to_hosts.sh")
    destination = "/tmp/add_ips_to_hosts.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.pooler_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "pooler_copy_nickname_script" {
  count = var.pooler_server["count"]

  depends_on = [
    aws_instance.pooler_server
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/add_nickname_to_shell.sh")
    destination = "/tmp/add_nickname_to_shell.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.pooler_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "pem-set-hostname" {
  count = var.pem_server["count"]

  depends_on = [
    null_resource.pem_copy_hostname_script
  ]

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /tmp/add_ips_to_hosts.sh",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pem ${join(" ", aws_instance.pem_server.*.private_ip)} >> /tmp/pem_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} postgres ${join(" ", aws_instance.postgres_server.*.private_ip)} >> /tmp/postgres_hostnames.log 2>&1",        
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} barman ${join(" ", aws_instance.barman_server.*.private_ip)} >> /tmp/barman_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pooler ${join(" ", aws_instance.pooler_server.*.private_ip)} >> /tmp/pooler_hostnames.log 2>&1",
        "chmod a+x /tmp/add_nickname_to_shell.sh",        
        "/tmp/add_nickname_to_shell.sh ${var.cluster_name} pem ${join(" ", aws_instance.pem_server.*.private_ip)} >> /tmp/pem_nicknames.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.pem_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "pg-set-hostname" {
  count = var.postgres_server["count"]

  depends_on = [
    null_resource.postgres_copy_hostname_script
  ]

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /tmp/add_ips_to_hosts.sh",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pem ${join(" ", aws_instance.pem_server.*.private_ip)} >> /tmp/pem_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} postgres ${join(" ", aws_instance.postgres_server.*.private_ip)} >> /tmp/postgres_hostnames.log 2>&1",        
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} barman ${join(" ", aws_instance.barman_server.*.private_ip)} >> /tmp/barman_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pooler ${join(" ", aws_instance.pooler_server.*.private_ip)} >> /tmp/pooler_hostnames.log 2>&1",
        "chmod a+x /tmp/add_nickname_to_shell.sh",        
        "/tmp/add_nickname_to_shell.sh ${var.cluster_name} postgres ${join(" ", aws_instance.postgres_server.*.private_ip)} >> /tmp/postgres_nicknames.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.postgres_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "barman-set-hostname" {
  count = var.barman_server["count"]

  depends_on = [
    null_resource.barman_copy_hostname_script
  ]

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /tmp/add_ips_to_hosts.sh",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pem ${join(" ", aws_instance.pem_server.*.private_ip)} >> /tmp/pem_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} postgres ${join(" ", aws_instance.postgres_server.*.private_ip)} >> /tmp/postgres_hostnames.log 2>&1",        
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} barman ${join(" ", aws_instance.barman_server.*.private_ip)} >> /tmp/barman_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pooler ${join(" ", aws_instance.pooler_server.*.private_ip)} >> /tmp/pooler_hostnames.log 2>&1",
        "chmod a+x /tmp/add_nickname_to_shell.sh",        
        "/tmp/add_nickname_to_shell.sh ${var.cluster_name} barman ${join(" ", aws_instance.barman_server.*.private_ip)} >> /tmp/barman_nicknames.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.barman_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "pooler-set-hostname" {
  count = var.pooler_server["count"]

  depends_on = [
    null_resource.pooler_copy_hostname_script
  ]

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /tmp/add_ips_to_hosts.sh",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pem ${join(" ", aws_instance.pem_server.*.private_ip)} >> /tmp/pem_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} postgres ${join(" ", aws_instance.postgres_server.*.private_ip)} >> /tmp/postgres_hostnames.log 2>&1",        
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} barman ${join(" ", aws_instance.barman_server.*.private_ip)} >> /tmp/barman_hostnames.log 2>&1",
        "/tmp/add_ips_to_hosts.sh ${var.cluster_name} pooler ${join(" ", aws_instance.pooler_server.*.private_ip)} >> /tmp/pooler_hostnames.log 2>&1",
        "chmod a+x /tmp/add_nickname_to_shell.sh",        
        "/tmp/add_nickname_to_shell.sh ${var.cluster_name} pooler ${join(" ", aws_instance.pooler_server.*.private_ip)} >> /tmp/pooler_nicknames.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(aws_instance.pooler_server.*.public_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}
