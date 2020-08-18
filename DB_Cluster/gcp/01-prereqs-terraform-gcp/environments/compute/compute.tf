variable instance_count {}
variable instance_name {}
variable vm_type {}
variable network_name {}
variable subnetwork_name {}
variable subnetwork_region {}
variable os {}
variable ssh_user {}
variable ssh_key_location {}

data "google_compute_zones" "available" {
  region = var.subnetwork_region
}

resource "google_compute_instance" "edb-prereq-engine-instance" {
  count        = var.instance_count
  name         = "${var.instance_name}-${count.index}"
  machine_type = var.vm_type

  zone = data.google_compute_zones.available.names[count.index < 3 ? count.index : 2]

  tags = [
    "${var.network_name}-firewall-ssh",
    "${var.network_name}-firewall-http",
    "${var.network_name}-firewall-https",
    "${var.network_name}-firewall-icmp",
    "${var.network_name}-firewall-postgresql",
    "${var.network_name}-firewall-epas",
    "${var.network_name}-firewall-efm",
    "${var.network_name}-firewall-openshift-console",
    "${var.network_name}-firewall-secure-forward",
  ]

  boot_disk {
    initialize_params {
      image = var.os
      size  = 20
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_key_location)}"
  }

  network_interface {
    #subnetwork = google_compute_subnetwork.edb_prereq_network_subnetwork.name
    subnetwork = var.subnetwork_name

    access_config {
      // Ephemeral IP
    }

  }
}
