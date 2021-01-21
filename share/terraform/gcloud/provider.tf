provider "google" {
  credentials = var.gcloud_credentials
  project     = var.gcloud_project_id
}
