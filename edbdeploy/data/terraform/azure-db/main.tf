module "resourcegroup" {
  source = "./environments/resourcegroup"

  resourcegroup_name = var.resourcegroup_name
  resourcegroup_tag  = var.resourcegroup_tag
  azure_region       = var.azure_region
}

module "security" {
  source = "./environments/security"

  securitygroup_name = var.securitygroup_name
  resourcegroup_name = var.resourcegroup_name
  azure_region       = var.azure_region
  project_tag        = var.project_tag

  depends_on = [module.resourcegroup]
}

module "network" {
  source = "./environments/network"

  securitygroup_name = var.securitygroup_name
  resourcegroup_name = var.resourcegroup_name
  azure_region       = var.azure_region
  vnet_name          = var.vnet_name
  vnet_cidr_block    = var.vnet_cidr_block

  depends_on = [module.resourcegroup]
}

module "vm" {
  source = "./environments/vm"

  postgres_server                 = var.postgres_server
  pg_version                      = var.pg_version
  pem_server                      = var.pem_server
  dbt2                            = var.dbt2
  dbt2_client                     = var.dbt2_client
  dbt2_driver                     = var.dbt2_driver
  hammerdb_server                 = var.hammerdb_server
  cluster_name                    = var.cluster_name
  vnet_name                       = var.vnet_name
  resourcegroup_name              = var.resourcegroup_name
  securitygroup_name              = var.securitygroup_name
  azure_region                    = var.azure_region
  ssh_pub_key                     = var.ssh_pub_key
  ssh_priv_key                    = var.ssh_priv_key
  project_tags                    = var.project_tags
  azure_publisher                 = var.azure_publisher
  azure_offer                     = var.azure_offer
  azure_sku                       = var.azure_sku
  azuredb_passwd                  = var.azuredb_passwd
  azuredb_sku                     = var.azuredb_sku
  ssh_user                        = var.ssh_user
  ansible_inventory_yaml_filename = var.ansible_inventory_yaml_filename
  add_hosts_filename              = var.add_hosts_filename
  hammerdb                        = var.hammerdb
  network_count                   = var.postgres_server["count"] + var.hammerdb_server["count"]
  guc_effective_cache_size        = var.guc_effective_cache_size
  guc_max_wal_size                = var.guc_max_wal_size

  depends_on = [module.network]
}
