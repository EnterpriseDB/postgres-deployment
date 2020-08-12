module "network" {
  source = "./environments/network"

  network_name = var.network_name
  subnetwork_region = var.subnetwork_region
  ip_cidr_range = var.ip_cidr_range

}

module "security" {
  source = "./environments/security"

  network_name = var.network_name
  source_ranges = var.source_ranges

  depends_on = [module.network]
  
}

module "compute" {
  source = "./environments/compute"
  
  instance_count = var.instance_count
  instance_name = var.instance_name
  vm_type = var.vm_type
  network_name = var.network_name
  subnetwork_name = var.subnetwork_name
  subnetwork_region = var.subnetwork_region
  os = var.os
  ssh_user = var.ssh_user
  ssh_key_location = var.ssh_key_location

  depends_on = [module.security]
}
