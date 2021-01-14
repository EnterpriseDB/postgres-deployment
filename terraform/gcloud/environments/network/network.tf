variable "instance_name" {}
variable "network_name" {}
variable "subnetwork_region" {}
variable "ip_cidr_range" {}

resource "google_compute_network" "edb_prereq_network" {
  name = var.instance_name
}

resource "google_compute_subnetwork" "edb_prereq_network_subnetwork" {
  name          = format("%s-%s-%s", var.instance_name, "subnetwork", var.subnetwork_region)
  region        = var.subnetwork_region
  network       = google_compute_network.edb_prereq_network.self_link
  ip_cidr_range = var.ip_cidr_range
}
