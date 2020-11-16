variable instance_count {}
variable pem_instance_count {}
variable synchronicity {}
variable instance_name {}
variable vm_type {}
variable network_name {}
variable subnetwork_name {}
variable subnetwork_region {}
variable os {}
variable ssh_user {}
variable ssh_key_location {}
variable ansible_pem_inventory_yaml_filename {}
variable os_csv_filename {}
variable add_hosts_filename {}

data "google_compute_zones" "available" {
  region = var.subnetwork_region
}

resource "google_compute_instance" "edb-prereq-engine-instance" {
  count        = var.instance_count
  name         = (var.pem_instance_count == "1" && count.index == 0 ? format("%s-%s", var.instance_name, "pemserver") : (var.pem_instance_count == "0" && count.index == 1 ? format("%s-%s", var.instance_name, "primary") : (count.index > 1 ? format("%s-%s%s", var.instance_name, "standby", count.index) : format("%s-%s%s", var.instance_name, "primary", count.index))))
  machine_type = var.vm_type

  zone = data.google_compute_zones.available.names[count.index < 3 ? count.index : 2]

#  tags = [
#    "${var.network_name}-firewall-ssh",
#    "${var.network_name}-firewall-http",
#    "${var.network_name}-firewall-https",
#    "${var.network_name}-firewall-icmp",
#    "${var.network_name}-firewall-postgresql",
#    "${var.network_name}-firewall-epas",
#    "${var.network_name}-firewall-efm",
#    "${var.network_name}-firewall-openshift-console",
#    "${var.network_name}-firewall-secure-forward",
#  ]

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
    initialize_params {
      image = var.os
      size  = 20
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_key_location)}"
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      // Ephemeral IP
    }

  }
}
