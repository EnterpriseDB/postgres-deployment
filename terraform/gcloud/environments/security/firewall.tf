variable "network_name" {}
variable "source_ranges" {}

resource "google_compute_firewall" "ssh" {
  #name    = "${var.network_name}-firewall-ssh"
  name    = format("%s-%s", var.network_name, "firewall-ssh")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  #target_tags   = ["${var.network_name}-firewall-ssh"]
  target_tags = [format("%s-%s", var.network_name, "firewall-ssh")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "http" {
  #name    = "${var.network_name}-firewall-http"
  name    = format("%s-%s", var.network_name, "firewall-http")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  #target_tags   = ["${var.network_name}-firewall-http"]
  target_tags = [format("%s-%s", var.network_name, "firewall-http")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "https" {
  #name    = "${var.network_name}-firewall-https"
  name    = format("%s-%s", var.network_name, "firewall-https")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  #target_tags   = ["${var.network_name}-firewall-https"]
  target_tags = [format("%s-%s", var.network_name, "firewall-https")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "icmp" {
  #name    = "${var.network_name}-firewall-icmp"
  name    = format("%s-%s", var.network_name, "firewall-icmp")
  network = var.network_name

  allow {
    protocol = "icmp"
  }

  #target_tags   = ["${var.network_name}-firewall-icmp"]
  target_tags = [format("%s-%s", var.network_name, "firewall-icmp")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "postgresql" {
  #name    = "${var.network_name}-firewall-postgresql"
  name    = format("%s-%s", var.network_name, "firewall-postgresql")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  #target_tags   = ["${var.network_name}-firewall-postgresql"]
  target_tags = [format("%s-%s", var.network_name, "firewall-postgresql")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "epas" {
  #name    = "${var.network_name}-firewall-epas"
  name    = format("%s-%s", var.network_name, "firewall-epas")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["5444"]
  }

  #target_tags   = ["${var.network_name}-firewall-epas"]
  target_tags = [format("%s-%s", var.network_name, "firewall-epas")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "efm" {
  #name    = "${var.network_name}-firewall-efm"
  name    = format("%s-%s", var.network_name, "firewall-efm")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["7800-7810"]
  }

  #target_tags   = ["${var.network_name}-firewall-epas"]
  target_tags = [format("%s-%s", var.network_name, "firewall-efm")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "firewall-openshift-console" {
  #name    = "${var.network_name}-firewall-openshift-console"
  name    = format("%s-%s", var.network_name, "firewall-openshift-console")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  #target_tags   = ["${var.network_name}-firewall-openshift-console"]
  target_tags = [format("%s-%s", var.network_name, "firewall-openshift-console")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "firewall-secure-forward" {
  #name = "${var.network_name}-firewall-secure-forward"
  name = format("%s-%s", var.network_name, "firewall-secure-forward")
  #network = google_compute_network.edb_prereq_network.name
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["24284"]
  }

  #target_tags   = ["${var.network_name}-firewall-secure-forward"]
  target_tags = [format("%s-%s", var.network_name, "firewall-secure-forward")]
  #source_ranges = ["${var.source_ranges}"]
  source_ranges = [var.source_ranges]
}
