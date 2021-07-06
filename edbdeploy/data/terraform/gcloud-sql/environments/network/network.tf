variable "subnetwork_name" {}
variable "network_name" {}
variable "gcloud_region" {}
variable "ip_cidr_range" {}

resource "google_compute_network" "edb_prereq_network" {
  name = var.network_name
}

resource "google_compute_subnetwork" "edb_prereq_network_subnetwork" {
  name          = format("%s-%s", var.subnetwork_name, var.gcloud_region)
  region        = var.gcloud_region
  network       = google_compute_network.edb_prereq_network.self_link
  ip_cidr_range = var.ip_cidr_range
}
