module "iam" {
  source = "./global/iam"

  user_name          = var.user_name
  user_path          = var.user_path
  user_force_destroy = var.user_force_destroy
  project_tags       = var.project_tags
}

module "vpc" {
  source = "./environments/vpc"

  vpc_cidr_block = var.vpc_cidr_block
  vpc_tag        = var.vpc_tag

  depends_on = [module.iam]
}

module "network" {
  source = "./environments/network"

  instance_count    = var.instance_count
  vpc_id            = module.vpc.vpc_id
  public_subnet_tag = var.public_subnet_tag
  aws_region        = var.aws_region

  depends_on = [module.vpc]
}

module "policies" {
  source = "./environments/policies/"

  aws_iam_user_name = module.iam.aws_iam_user_name
  project_tag       = var.project_tag

  depends_on = [module.network]
}

module "routes" {
  source = "./environments/routes"

  instance_count   = var.instance_count
  vpc_id           = module.vpc.vpc_id
  project_tag      = var.project_tag
  public_cidrblock = var.public_cidrblock

  depends_on = [module.policies]
}

module "security" {
  source = "./environments/security"

  vpc_id           = module.vpc.vpc_id
  public_cidrblock = var.public_cidrblock
  project_tag      = var.project_tag

  depends_on = [module.routes]
}

module "edb-db-cluster" {
  # The source module used for creating AWS clusters.
  source = "./environments/ec2"

  os                                  = var.os
  vpc_id                              = module.vpc.vpc_id
  instance_count                      = var.instance_count
  pem_instance_count                  = var.pem_instance_count
  synchronicity = var.synchronicity
  cluster_name                        = var.cluster_name
  instance_type                       = var.instance_type
  ansible_inventory_yaml_filename     = var.ansible_inventory_yaml_filename
  ansible_pem_inventory_yaml_filename = var.ansible_pem_inventory_yaml_filename
  ansible_inventory_ini_filename      = var.ansible_inventory_ini_filename
  os_csv_filename                     = var.os_csv_filename
  add_hosts_filename                  = var.add_hosts_filename
  custom_security_group_id            = module.security.aws_security_group_id
  ssh_keypair                         = var.ssh_keypair
  ssh_key_path                        = var.ssh_key_path
  created_by                          = var.created_by

  depends_on = [module.routes]
}
