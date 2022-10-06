variable "project_id" {
  description = "project id"
}

variable "gcpRegion" {
  description = "region"
}

variable "kClusterName" {
  description = "GKE Cluster Name"
}

variable "gke_username" {
  description = "gke username"
}

variable "gke_password" {
  description = "gke password"
}

variable "gke_num_nodes" {
  description = "number of gke nodes"
}

variable "gke_machine_type" {
  description = "Machine Type for k8s cluster"
}

variable "gke_ip_cidr_range" {
  description = "IP CIDR Range for k8s cluster"
}

variable "gcp_credentials_file" {
  description = "GCP Credentials File"
}
