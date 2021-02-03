variable "add_hosts_filename" {}
variable "ansible_inventory_yaml_filename" {}
variable "barman" {}
variable "barman_server" {}
variable "cluster_name" {}
variable "gcloud_image" {}
variable "gcloud_region" {}
variable "network_name" {}
variable "pem_server" {}
variable "pooler_local" {}
variable "pooler_server" {}
variable "pooler_type" {}
variable "postgres_server" {}
variable "replication_type" {}
variable "ssh_priv_key" {}
variable "ssh_pub_key" {}
variable "ssh_user" {}
variable "subnetwork_name" {}

locals {
  lnx_device_names = [
    "/dev/sdb",
    "/dev/sdc",
    "/dev/sdd",
    "/dev/sde",
    "/dev/sdf"
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
  barman_mount_points = [
    "/var/lib/barman"
  ]
}

data "google_compute_zones" "available" {
  region = var.gcloud_region
}

resource "google_compute_address" "postgres_public_ip" {
  count  = var.postgres_server["count"]
  name   = format("postgres-public-ip-%s", count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_instance" "postgres_server" {
  count        = var.postgres_server["count"]
  name         = (count.index == 0 ? format("%s-%s", var.cluster_name, "primary") : format("%s-%s%s", var.cluster_name, "standby", count.index))
  machine_type = var.postgres_server["instance_type"]

  zone = element(data.google_compute_zones.available.names, count.index)

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-postgresql"),
    format("%s-%s", var.network_name, "firewall-epas"),
    format("%s-%s", var.network_name, "firewall-efm"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    initialize_params {
      image = var.gcloud_image
      type  = var.postgres_server["volume"]["type"]
      size  = var.postgres_server["volume"]["size"]
    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      nat_ip = element(google_compute_address.postgres_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
}

resource "google_compute_disk" "postgres_volumes" {
  count = var.postgres_server["count"] * var.postgres_server["additional_volumes"]["count"]
  name  = format("%s-postgres-disk-%s", var.cluster_name, count.index)
  type  = var.postgres_server["additional_volumes"]["type"]
  size  = var.postgres_server["additional_volumes"]["size"]
  zone  = element(data.google_compute_zones.available.names, floor(count.index / var.postgres_server["additional_volumes"]["count"]))

  depends_on = [google_compute_instance.postgres_server]
}

resource "google_compute_attached_disk" "postgres_attached_vol" {
  count    = var.postgres_server["count"] * var.postgres_server["additional_volumes"]["count"]
  disk     = element(google_compute_disk.postgres_volumes.*.id, count.index)
  instance = element(google_compute_instance.postgres_server.*.id, floor(count.index / var.postgres_server["additional_volumes"]["count"]))

  depends_on = [google_compute_disk.postgres_volumes]
}

resource "null_resource" "postgres_copy_setup_volume_script" {
  count = var.postgres_server["count"]

  depends_on = [
    google_compute_attached_disk.postgres_attached_vol
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/setup_volume.sh")
    destination = "/tmp/setup_volume.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(google_compute_instance.postgres_server.*.network_interface.0.access_config.0.nat_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "null_resource" "postgres_setup_volume" {
  count = var.postgres_server["count"] * var.postgres_server["additional_volumes"]["count"]

  depends_on = [
    null_resource.postgres_copy_setup_volume_script
  ]

  provisioner "remote-exec" {
    inline = [
        "chmod a+x /tmp/setup_volume.sh",
        "/tmp/setup_volume.sh ${element(local.lnx_device_names, floor(count.index / var.postgres_server["count"]))} ${element(local.postgres_mount_points, floor(count.index / var.postgres_server["count"]))} >> /tmp/mount.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(google_compute_instance.postgres_server.*.network_interface.0.access_config.0.nat_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "google_compute_address" "barman_public_ip" {
  count  = var.barman_server["count"]
  name   = format("barman-public-ip-%s", count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_instance" "barman_server" {
  count        = var.barman_server["count"]
  name         = format("%s-%s%s", var.cluster_name, "barman", count.index + 1)
  machine_type = var.barman_server["instance_type"]

  zone = element(data.google_compute_zones.available.names, count.index)

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    initialize_params {
      image = var.gcloud_image
      type  = var.barman_server["volume"]["type"]
      size  = var.barman_server["volume"]["size"]
    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      nat_ip = element(google_compute_address.barman_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
}

resource "google_compute_disk" "barman_volumes" {
  count = var.barman_server["count"] * var.barman_server["additional_volumes"]["count"]
  name  = format("%s-barman-disk-%s", var.cluster_name, count.index)
  type  = var.barman_server["additional_volumes"]["type"]
  size  = var.barman_server["additional_volumes"]["size"]
  zone  = element(data.google_compute_zones.available.names, floor(count.index / var.barman_server["additional_volumes"]["count"]))

  depends_on = [google_compute_instance.barman_server]
}

resource "google_compute_attached_disk" "barman_attached_vol" {
  count    = var.barman_server["count"] * var.barman_server["additional_volumes"]["count"]
  disk     = element(google_compute_disk.barman_volumes.*.id, count.index)
  instance = element(google_compute_instance.barman_server.*.id, floor(count.index / var.barman_server["additional_volumes"]["count"]))

  depends_on = [google_compute_disk.barman_volumes]
}

resource "null_resource" "barman_copy_setup_volume_script" {
  count = var.barman_server["count"]

  depends_on = [
    google_compute_attached_disk.barman_attached_vol
  ]

  provisioner "file" {
    content     = file("${abspath(path.module)}/setup_volume.sh")
    destination = "/tmp/setup_volume.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(google_compute_instance.barman_server.*.network_interface.0.access_config.0.nat_ip, count.index)
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
        "/tmp/setup_volume.sh ${element(local.lnx_device_names, floor(count.index / var.barman_server["count"]))} ${element(local.barman_mount_points, floor(count.index / var.barman_server["count"]))} >> /tmp/mount.log 2>&1"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = element(google_compute_instance.barman_server.*.network_interface.0.access_config.0.nat_ip, count.index)
      private_key = file(var.ssh_priv_key)
    }
  }
}

resource "google_compute_address" "pem_public_ip" {
  count  = var.pem_server["count"]
  name   = format("pem-public-ip-%s", count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_instance" "pem_server" {
  count        = var.pem_server["count"]
  name         = format("%s-%s%s", var.cluster_name, "pemserver", count.index + 1)
  machine_type = var.pem_server["instance_type"]

  zone = element(data.google_compute_zones.available.names, count.index)

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-http"),
    format("%s-%s", var.network_name, "firewall-postgresql"),
    format("%s-%s", var.network_name, "firewall-epas"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-pem-server"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    initialize_params {
      image = var.gcloud_image
      type  = var.pem_server["volume"]["type"]
      size  = var.pem_server["volume"]["size"]
    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      nat_ip = element(google_compute_address.pem_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
}

resource "google_compute_address" "pooler_public_ip" {
  count  = var.pooler_server["count"]
  name   = format("pooler-public-ip-%s", count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_instance" "pooler_server" {
  count        = var.pooler_server["count"]
  name         = format("%s-%s%s", var.cluster_name, "pooler", count.index + 1)
  machine_type = var.pooler_server["instance_type"]

  zone = element(data.google_compute_zones.available.names, count.index)

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-pgpool"),
    format("%s-%s", var.network_name, "firewall-pgpool-watchdog"),
    format("%s-%s", var.network_name, "firewall-pgpool-watchdoghb"),
    format("%s-%s", var.network_name, "firewall-pgpool-pcp"),
    format("%s-%s", var.network_name, "firewall-pgpool-watchdogudp"),
    format("%s-%s", var.network_name, "firewall-pgpool-watchdoghbudp"),
    format("%s-%s", var.network_name, "firewall-pgpool-pcpudp"),
    format("%s-%s", var.network_name, "firewall-pgbouncer"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    initialize_params {
      image = var.gcloud_image
      type  = var.pooler_server["volume"]["type"]
      size  = var.pooler_server["volume"]["size"]
    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      nat_ip = element(google_compute_address.pooler_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
}
