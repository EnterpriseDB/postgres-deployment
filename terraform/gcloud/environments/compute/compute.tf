variable "pg_instance_count" {
	type = number
}
variable "pem_instance_count" {
	type = number
}
variable "synchronicity" {}
variable "instance_name" {}
variable "vm_type" {}
variable "vm_disk_type" {}
variable "vm_disk_size" {}
variable "volume_count" {}
variable "volume_disk_type" {}
variable "volume_disk_size" {}
variable "network_name" {}
variable "subnetwork_name" {}
variable "subnetwork_region" {}
variable "os" {}
variable "ssh_user" {}
variable "ssh_key_location" {}
variable "ansible_inventory_yaml_filename" {}
variable "os_csv_filename" {}
variable "add_hosts_filename" {}
variable "hosts_filename" {}
variable "full_private_ssh_key_path" {}
variable "disk_encryption_key" {}


data "google_compute_zones" "available" {
  region = var.subnetwork_region
}

resource "google_compute_instance" "pg_server" {
  count        = var.pg_instance_count
  name         = (count.index == 0 ? format("%s-%s", var.instance_name, "primary") : format("%s-%s%s", var.instance_name, "standby", count.index))
  machine_type = var.vm_type

  #zone = data.google_compute_zones.available.names[count.index < 3 ? count.index : 2]
  zone = data.google_compute_zones.available.names[0]

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-http"),
    format("%s-%s", var.network_name, "firewall-https"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-postgresql"),
    format("%s-%s", var.network_name, "firewall-epas"),
    format("%s-%s", var.network_name, "firewall-efm"),
    format("%s-%s", var.network_name, "firewall-openshift-console"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    # Un-comment to enable Disk Encryption
    #disk_encryption_key_raw = base64encode(var.disk_encryption_key)
    disk_encryption_key_raw = var.disk_encryption_key

    initialize_params {
      image = var.os
      type  = var.vm_disk_type
      size  = var.vm_disk_size

    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      // Ephemeral IP
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_key_location))
  }

  metadata_startup_script = file("../../terraform/gcloud/environments/compute/setup_volumes.sh")

}

resource "google_compute_disk" "pg_volumes" {
  count = var.pg_instance_count * var.volume_count
  name  = format("%s-%s", var.network_name, count.index)
  type  = var.volume_disk_type
  size  = var.volume_disk_size
  zone  = data.google_compute_zones.available.names[0]

  # Currently in beta and not supported
  # If un-commented provisioning of resources will fail
  # disk_encryption_key {
  #   raw_key = var.disk_encryption_key
  # }

  depends_on = [google_compute_instance.pg_server]
}

resource "google_compute_attached_disk" "pg_server_attached_disk" {
  count    = var.pg_instance_count * var.volume_count
  disk     = element(google_compute_disk.pg_volumes.*.id, count.index)
  instance = element(google_compute_instance.pg_server.*.id, count.index)

  depends_on = [google_compute_disk.pg_volumes]

}

// PEM Server
resource "google_compute_instance" "pem_server" {
  count        = var.pem_instance_count
  name         = format("%s-%s", var.instance_name, "pemserver")
  machine_type = var.vm_type

  #zone = data.google_compute_zones.available.names[count.index < 3 ? count.index : 2]
  zone = data.google_compute_zones.available.names[0]

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-http"),
    format("%s-%s", var.network_name, "firewall-https"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-postgresql"),
    format("%s-%s", var.network_name, "firewall-epas"),
    format("%s-%s", var.network_name, "firewall-efm"),
    format("%s-%s", var.network_name, "firewall-openshift-console"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    # Un-comment to enable Disk Encryption
    #disk_encryption_key_raw = base64encode(var.disk_encryption_key)
    disk_encryption_key_raw = var.disk_encryption_key

    initialize_params {
      image = var.os
      type  = var.vm_disk_type
      size  = var.vm_disk_size

    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      // Ephemeral IP
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_key_location))
  }

  metadata_startup_script = file("../../terraform/gcloud/environments/compute/setup_volumes.sh")

}

resource "google_compute_disk" "pem_volumes" {
  count = var.pem_instance_count * var.volume_count
  name  = format("%s-%s", var.network_name, count.index)
  type  = var.volume_disk_type
  size  = var.volume_disk_size
  zone  = data.google_compute_zones.available.names[0]

  # Currently in beta and not supported
  # If un-commented provisioning of resources will fail
  # disk_encryption_key {
  #   raw_key = var.disk_encryption_key
  # }

  depends_on = [google_compute_instance.pem_server]
}

resource "google_compute_attached_disk" "pem_server_attached_disk" {
  count    = var.pem_instance_count * var.volume_count
  disk     = element(google_compute_disk.pem_volumes.*.id, count.index)
  instance = element(google_compute_instance.pem_server.*.id, count.index)

  depends_on = [google_compute_disk.pem_volumes]

}
