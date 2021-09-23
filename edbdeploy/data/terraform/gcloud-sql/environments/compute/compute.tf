variable "add_hosts_filename" {}
variable "ansible_inventory_yaml_filename" {}
variable "cluster_name" {}
variable "dbt2" {}
variable "dbt2_client" {}
variable "dbt2_driver" {}
variable "gcloud_image" {}
variable "gcloud_project_id" {}
variable "gcloud_region" {}
variable "hammerdb_server" {}
variable "hammerdb" {}
variable "ip_cidr_range" {}
variable "network_name" {}
variable "pem_server" {}
variable "postgres_server" {}
variable "pg_version" {}
variable "ssh_priv_key" {}
variable "ssh_pub_key" {}
variable "ssh_user" {}
variable "source_ranges" {}
variable "subnetwork_name" {}
variable "guc_effective_cache_size" {}
variable "guc_shared_buffers" {}
variable "guc_max_wal_size" {}

resource "google_compute_network" "edb_prereq_network" {
  name = var.network_name
}

resource "google_compute_subnetwork" "edb_prereq_network_subnetwork" {
  name          = var.subnetwork_name
  region        = var.gcloud_region
  network       = google_compute_network.edb_prereq_network.self_link
  ip_cidr_range = var.ip_cidr_range
}

resource "google_compute_firewall" "ssh" {
  name    = format("%s-%s", var.network_name, "firewall-ssh")
  network = google_compute_network.edb_prereq_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-ssh")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "http" {
  name    = format("%s-%s", var.network_name, "firewall-http")
  network = google_compute_network.edb_prereq_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-http")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "https" {
  name    = format("%s-%s", var.network_name, "firewall-https")
  network = google_compute_network.edb_prereq_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-https")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "icmp" {
  name    = format("%s-%s", var.network_name, "firewall-icmp")
  network = google_compute_network.edb_prereq_network.name

  allow {
    protocol = "icmp"
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-icmp")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "postgresql" {
  name    = format("%s-%s", var.network_name, "firewall-postgresql")
  network = google_compute_network.edb_prereq_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-postgresql")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "pem-server" {
  name    = format("%s-%s", var.network_name, "firewall-pem-server")
  network = google_compute_network.edb_prereq_network.name

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-pem-server")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "firewall-secure-forward" {
  name    = format("%s-%s", var.network_name, "firewall-secure-forward")
  network = google_compute_network.edb_prereq_network.name

  allow {
    protocol = "tcp"
    ports    = ["24284"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-secure-forward")]
  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "dbt2-client" {
  name    = format("%s-%s", var.network_name, "firewall-dbt-2-client")
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["30000"]
  }

  target_tags   = [format("%s-%s", var.network_name, "firewall-dbt-2-client")]
  source_ranges = [var.source_ranges]
}

data "google_compute_zones" "available" {
  region = var.gcloud_region
}

resource "google_compute_address" "dbt2_client_public_ip" {
  count  = var.dbt2_client["count"]
  name   = format("%s-dbt-2-client-public-ip-%s", var.cluster_name, count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_instance" "dbt2_client" {
  count        = var.dbt2_client["count"]
  name         = (count.index == 0 ? format("%s-%s", var.cluster_name, "dbt2client") : format("%s-%s%s", var.cluster_name, "dbt2client", count.index))
  machine_type = var.dbt2_client["instance_type"]

  zone = element(data.google_compute_zones.available.names, count.index)

  tags = [
    format("%s-%s", var.network_name, "firewall-dbt-2-client"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
    format("%s-%s", var.network_name, "firewall-ssh"),
  ]

  boot_disk {
    initialize_params {
      image = var.gcloud_image
      type  = var.dbt2_client["volume"]["type"]
      size  = var.dbt2_client["volume"]["size"]
    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      nat_ip = element(google_compute_address.dbt2_client_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
}

resource "google_compute_address" "dbt2_driver_public_ip" {
  count  = var.dbt2_driver["count"]
  name   = format("%s-dbt-2-driver-public-ip-%s", var.cluster_name, count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_instance" "dbt2_driver" {
  count        = var.dbt2_driver["count"]
  name         = (count.index == 0 ? format("%s-%s", var.cluster_name, "dbt2driver") : format("%s-%s%s", var.cluster_name, "dbt2driver", count.index))
  machine_type = var.dbt2_driver["instance_type"]

  zone = element(data.google_compute_zones.available.names, count.index)

  tags = [
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
    format("%s-%s", var.network_name, "firewall-ssh"),
  ]

  boot_disk {
    initialize_params {
      image = var.gcloud_image
      type  = var.dbt2_driver["volume"]["type"]
      size  = var.dbt2_driver["volume"]["size"]
    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      nat_ip = element(google_compute_address.dbt2_driver_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
}

resource "google_compute_address" "hammerdb_public_ip" {
  count  = var.hammerdb_server["count"]
  name   = format("%s-hammerdb-public-ip-%s", var.cluster_name, count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_address" "postgres_public_ip" {
  count  = var.postgres_server["count"]
  name   = format("%s-postgres-public-ip-%s", var.cluster_name, count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_address" "pem_public_ip" {
  count  = var.pem_server["count"]
  name   = format("pem-public-ip-%s", count.index + 1)
  region = var.gcloud_region
}

resource "google_compute_instance" "hammerdb_server" {
  count        = var.hammerdb_server["count"]
  name         = (count.index == 0 ? format("%s-%s", var.cluster_name, "hammerdb") : format("%s-%s%s", var.cluster_name, "standby", count.index))
  machine_type = var.hammerdb_server["instance_type"]

  zone = element(data.google_compute_zones.available.names, count.index)

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    initialize_params {
      image = var.gcloud_image
      type  = var.hammerdb_server["volume"]["type"]
      size  = var.hammerdb_server["volume"]["size"]
    }
  }

  network_interface {
    subnetwork = google_compute_network.edb_prereq_network.name

    access_config {
      nat_ip = element(google_compute_address.hammerdb_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
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
    subnetwork = google_compute_network.edb_prereq_network.name

    access_config {
      nat_ip = element(google_compute_address.pem_public_ip.*.address, count.index)
    }

  }

  metadata = {
    ssh-keys = format("%s:%s", var.ssh_user, file(var.ssh_pub_key))
  }
}

resource "google_sql_database_instance" "postgresql" {
  name                = format("%s-%s", var.cluster_name, "sql-postgresql-instance")
  project             = var.gcloud_project_id
  region              = var.gcloud_region
  database_version    = format("POSTGRES_%s", var.pg_version)
  deletion_protection = false

  settings {
    tier              = var.postgres_server["instance_type"]
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"
    disk_autoresize   = false
    disk_size         = var.postgres_server["volume"]["size"]
    disk_type         = var.postgres_server["volume"]["type"]

    location_preference {
      zone = element(data.google_compute_zones.available.names, 0)
    }

    maintenance_window {
      day  = "7" # sunday
      hour = "3" # 3am
    }

    backup_configuration {
      binary_log_enabled = false
      enabled            = false
      start_time         = "00:00"
    }

    ip_configuration {
      ipv4_enabled = true

      dynamic "authorized_networks" {
        for_each = google_compute_instance.hammerdb_server
        iterator = hammerdb_server
        content {
          name  = hammerdb_server.value.name
          value = hammerdb_server.value.network_interface.0.access_config.0.nat_ip
        }
      }
    }

    database_flags {
      name  = "checkpoint_timeout"
      value = "900"
    }

    database_flags {
      name  = "effective_cache_size"
      value = var.guc_effective_cache_size
    }

    database_flags {
      name  = "max_connections"
      value = "300"
    }

    database_flags {
      name  = "max_wal_size"
      value = var.guc_max_wal_size
    }

    database_flags {
      name  = "random_page_cost"
      value = "1.25"
    }

    database_flags {
      name  = "work_mem"
      value = "65536"
    }
  }
}

resource "google_sql_database" "postgresql_db" {
  name      = format("%s-%s", var.cluster_name, "sql-postgresql-database")
  instance  = google_sql_database_instance.postgresql.name
  charset   = "UTF-8"
  collation = "en_US.UTF8"
}

resource "random_id" "user_password" {
  byte_length = 16
}

resource "google_sql_user" "postgresql_user" {
  name     = "postgres"
  instance = google_sql_database_instance.postgresql.name
  password = random_id.user_password.hex
}
