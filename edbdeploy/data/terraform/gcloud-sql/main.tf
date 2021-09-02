#module "network" {
#  source = "./environments/network"
#
#  subnetwork_name   = var.subnetwork_name
#  network_name      = var.network_name
#  gcloud_region     = var.gcloud_region
#  ip_cidr_range     = var.ip_cidr_range
#}

#module "security" {
#  source = "./environments/security"
#
#  network_name  = var.network_name
#  source_ranges = var.source_ranges
#
#  depends_on = [module.network]
#}

module "compute" {
  source = "./environments/compute"

  postgres_server                 = var.postgres_server
  pem_server                      = var.pem_server
  hammerdb_server                 = var.hammerdb_server
  cluster_name                    = var.cluster_name
  network_name                    = var.network_name
  subnetwork_name                 = "${var.subnetwork_name}-${var.gcloud_region}"
  gcloud_image                    = var.gcloud_image
  gcloud_project_id               = var.gcloud_project_id
  gcloud_region                   = var.gcloud_region
  ssh_user                        = var.ssh_user
  ssh_pub_key                     = var.ssh_pub_key
  ssh_priv_key                    = var.ssh_priv_key
  ansible_inventory_yaml_filename = var.ansible_inventory_yaml_filename
  add_hosts_filename              = var.add_hosts_filename
  hammerdb                        = var.hammerdb
  pg_version                      = var.pg_version
  source_ranges                   = var.source_ranges
  ip_cidr_range                   = var.ip_cidr_range
  guc_effective_cache_size        = var.guc_effective_cache_size
  guc_shared_buffers              = var.guc_shared_buffers
  guc_max_wal_size                = var.guc_max_wal_size
}
