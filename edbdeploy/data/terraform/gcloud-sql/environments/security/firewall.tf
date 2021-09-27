variable "network_name" {}
variable "source_ranges" {}

resource "google_compute_firewall" "ssh" {
  name    = format("%s-%s", var.network_name, "firewall-ssh")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-ssh")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "http" {
  name    = format("%s-%s", var.network_name, "firewall-http")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-http")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "https" {
  name    = format("%s-%s", var.network_name, "firewall-https")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-https")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "icmp" {
  name    = format("%s-%s", var.network_name, "firewall-icmp")
  network = var.network_name

  allow {
    protocol = "icmp"
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-icmp")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "postgresql" {
  name    = format("%s-%s", var.network_name, "firewall-postgresql")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-postgresql")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "epas" {
  name    = format("%s-%s", var.network_name, "firewall-epas")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["5444"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-epas")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pem-server" {
  name    = format("%s-%s", var.network_name, "firewall-pem-server")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-pem-server")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgbouncer" {
  name    = format("%s-%s", var.network_name, "firewall-pgbouncer")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["6432"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-pgbouncer")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "firewall-secure-forward" {
  name    = format("%s-%s", var.network_name, "firewall-secure-forward")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["24284"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-secure-forward")]
  source_ranges = [var.source_ranges]
}
