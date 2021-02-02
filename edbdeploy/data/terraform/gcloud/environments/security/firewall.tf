variable "network_name" {}
variable "source_ranges" {}

resource "google_compute_firewall" "ssh" {
  name    = format("%s-%s", var.network_name, "firewall-ssh")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-ssh")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "http" {
  name    = format("%s-%s", var.network_name, "firewall-http")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-http")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "https" {
  name    = format("%s-%s", var.network_name, "firewall-https")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-https")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "icmp" {
  name    = format("%s-%s", var.network_name, "firewall-icmp")
  network = var.network_name

  allow {
    protocol = "icmp"
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-icmp")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "postgresql" {
  name    = format("%s-%s", var.network_name, "firewall-postgresql")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-postgresql")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "epas" {
  name    = format("%s-%s", var.network_name, "firewall-epas")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["5444"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-epas")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "efm" {
  name    = format("%s-%s", var.network_name, "firewall-efm")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["7800-7810"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-efm")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pem-server" {
  name    = format("%s-%s", var.network_name, "firewall-pem-server")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pem-server")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgpool" {
  name    = format("%s-%s", var.network_name, "firewall-pgpool")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["9999"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgpool")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgpool-pcp" {
  name    = format("%s-%s", var.network_name, "firewall-pgpool-pcp")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["9898"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgpool-pcp")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgpool-watchdog" {
  name    = format("%s-%s", var.network_name, "firewall-pgpool-watchdog")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["9000"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgpool-watchdog")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgpool-watchdoghb" {
  name    = format("%s-%s", var.network_name, "firewall-pgpool-watchdoghb")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["9694"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgpool-watchdoghb")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgpool-pcpudp" {
  name    = format("%s-%s", var.network_name, "firewall-pgpool-pcpudp")
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["9898"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgpool-pcpudp")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgpool-watchdogudp" {
  name    = format("%s-%s", var.network_name, "firewall-pgpool-watchdogudp")
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["9000"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgpool-watchdogudp")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgpool-watchdoghbudp" {
  name    = format("%s-%s", var.network_name, "firewall-pgpool-watchdoghbudp")
  network = var.network_name

  allow {
    protocol = "udp"
    ports    = ["9694"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgpool-watchdoghbudp")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pgbouncer" {
  name    = format("%s-%s", var.network_name, "firewall-pgbouncer")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["6432"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-pgbouncer")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "firewall-secure-forward" {
  name = format("%s-%s", var.network_name, "firewall-secure-forward")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["24284"]
  }

  target_tags = [format("%s-%s", var.network_name, "firewall-secure-forward")]
  source_ranges = [var.source_ranges]
}
