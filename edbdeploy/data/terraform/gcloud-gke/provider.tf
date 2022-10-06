provider "google" {
  project = var.project_id
  region  = var.gcpRegion
  credentials = file(var.gcp_credentials_file)
}
