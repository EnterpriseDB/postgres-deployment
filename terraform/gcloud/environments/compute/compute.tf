variable instance_count {}
variable "pem_instance_count" {}
variable "synchronicity" {}
variable instance_name {}
variable vm_type {}
variable network_name {}
variable subnetwork_name {}
variable subnetwork_region {}
variable os {}
variable ssh_user {}
variable ssh_key_location {}
variable ansible_inventory_yaml_filename {}
variable "ansible_pem_inventory_yaml_filename" {}
variable os_csv_filename {}
variable add_hosts_filename {}

data "google_compute_zones" "available" {
  region = var.subnetwork_region
}

resource "google_compute_instance" "edb-prereq-engine-instance" {
  count = var.instance_count
  name  = "${var.instance_name}-${count.index}"
  #name       = var.pem_instance_count == 0 ? (count.index == 0 ? format("%s-%s", var.instance_name, "primary") : format("%s-%s%s", var.instance_name, "standby", count.index)) : (count.index > 1 ? format("%s-%s%s", var.instance_name, "standby", count.index) : (count.index == 0 ? format("%s-%s", var.instance_name, "pemserver") : format("%s-%s", var.instance_name, "primary")))  
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
