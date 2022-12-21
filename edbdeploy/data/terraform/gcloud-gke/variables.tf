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
  default = ""
}

variable "gke_password" {
  description = "gke password"
  default = ""
}

variable "initial_gke_num_nodes" {
  description = "initial number of gke nodes"
  default = 1
}

variable "gke_num_nodes" {
  description = "number of gke nodes"
  default = 3
}

variable "gke_machine_type" {
  description = "Machine Type for k8s cluster"
  default = "n1-standard-1"
}

variable "gke_ip_cidr_range" {
  description = "IP CIDR Range for k8s cluster"
  default = "10.10.0.0/24"
}

variable "gcp_credentials_file" {
  description = "GCP Credentials File"
}
