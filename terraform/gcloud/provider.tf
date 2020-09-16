provider "google" {
  #credentials = file("${path.module}/../credentials/account.json")
  credentials = var.credentials
  project     = var.project_name
}
