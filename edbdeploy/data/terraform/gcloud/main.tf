module "network" {
  source = "./environments/network"

  subnetwork_name   = var.subnetwork_name
  network_name      = var.network_name
  gcloud_region     = var.gcloud_region
  ip_cidr_range     = var.ip_cidr_range
}

module "security" {
  source = "./environments/security"

  network_name  = var.network_name
  source_ranges = var.source_ranges

  depends_on = [module.network]
}

module "compute" {
  source = "./environments/compute"

  postgres_server                     = var.postgres_server
  pem_server                          = var.pem_server
  barman_server                       = var.barman_server
  pooler_server                       = var.pooler_server
  pooler_type                         = var.pooler_type
  pooler_local                        = var.pooler_local
  barman                              = var.barman
  replication_type                    = var.replication_type
  cluster_name                        = var.cluster_name
  network_name                        = var.network_name
  subnetwork_name                     = "${var.subnetwork_name}-${var.gcloud_region}"
  gcloud_region                       = var.gcloud_region
  gcloud_image                        = var.gcloud_image
  ssh_user                            = var.ssh_user
  ssh_pub_key                         = var.ssh_pub_key
  ssh_priv_key                        = var.ssh_priv_key
  ansible_inventory_yaml_filename     = var.ansible_inventory_yaml_filename
  add_hosts_filename                  = var.add_hosts_filename

  depends_on = [module.security]
}
