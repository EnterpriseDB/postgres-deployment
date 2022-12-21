# GKE cluster
resource "google_container_cluster" "primary" {
#  name     = format("%s-%s", var.kClusterName, "gke")
  name     = var.kClusterName
  location = var.gcpRegion

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = var.initial_gke_num_nodes

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.gcpRegion
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = var.gke_machine_type
    tags         = [format("%s-%s", var.kClusterName, "gke-node"), format("%s-%s", var.kClusterName, "gke")]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}