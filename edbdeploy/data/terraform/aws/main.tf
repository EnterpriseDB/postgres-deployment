#module "iam" {
#  source = "./global/iam"
#
#  user_name          = var.user_name
#  user_path          = var.user_path
#  user_force_destroy = var.user_force_destroy
#  project_tags       = var.project_tags
#}

module "vpc" {
  source = "./environments/vpc"

  vpc_cidr_block = var.vpc_cidr_block
  vpc_tag        = var.vpc_tag

  #  depends_on = [module.iam]
}

module "network" {
  source = "./environments/network"

  network_count      = var.pooler_server["count"] > var.postgres_server["count"] ? var.pooler_server["count"] : var.postgres_server["count"]
  vpc_id             = module.vpc.vpc_id
  public_subnet_tag  = var.public_subnet_tag

  depends_on = [module.vpc]
}

#module "policies" {
#  source = "./environments/policies/"
#
#  aws_iam_user_name = module.iam.aws_iam_user_name
#  project_tag       = var.project_tag
#
#  depends_on = [module.network]
#}

module "routes" {
  source = "./environments/routes"

  postgres_count     = var.postgres_server["count"]
  pem_count          = var.pem_server["count"]
  hammerdb_count     = var.hammerdb_server["count"]
  barman_count       = var.barman_server["count"]
  pooler_count       = var.pooler_server["count"]
  vpc_id             = module.vpc.vpc_id
  project_tag        = var.project_tag
  public_cidrblock   = var.public_cidrblock

  #  depends_on = [module.policies]
  depends_on = [module.network]
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

  aws_ami_id                          = var.aws_ami_id
  vpc_id                              = module.vpc.vpc_id
  postgres_server                     = var.postgres_server
  pem_server                          = var.pem_server
  hammerdb_server                     = var.hammerdb_server
  barman_server                       = var.barman_server
  pooler_server                       = var.pooler_server
  replication_type                    = var.replication_type
  cluster_name                        = var.cluster_name
  ansible_inventory_yaml_filename     = var.ansible_inventory_yaml_filename
  add_hosts_filename                  = var.add_hosts_filename
  custom_security_group_id            = module.security.aws_security_group_id
  ssh_pub_key                         = var.ssh_pub_key
  ssh_priv_key                        = var.ssh_priv_key
  ssh_user                            = var.ssh_user
  created_by                          = var.created_by
  barman                              = var.barman
  pooler_type                         = var.pooler_type
  pooler_local                        = var.pooler_local
  hammerdb                            = var.hammerdb

  depends_on = [module.routes]
}
