module "iam" {
  source = "./global/iam"

  user_name          = var.user_name
  user_path          = var.user_path
  user_force_destroy = var.user_force_destroy
  project_tags       = var.project_tags
}

module "s3" {
  source = "./global/s3"

  aws_bucket_name = var.aws_bucket_name
  project_tags    = var.project_tags
}

module "vpc" {
  source = "./environment/vpc"

  vpc_cidr_block = var.vpc_cidr_block
  vpc_tag        = var.vpc_tag
}

module "network" {
  source = "./environment/network"

  vpc_id                    = module.vpc.vpc_id
  public_subnet_1_cidrblock = var.public_subnet_1_cidrblock
  public_subnet_2_cidrblock = var.public_subnet_2_cidrblock
  public_subnet_3_cidrblock = var.public_subnet_3_cidrblock
  public_subnet_tag         = var.public_subnet_tag
  aws_region                = var.aws_region
}

module "policies" {
  source = "./environment/policies/"

  aws_iam_user_name = module.iam.aws_iam_user_name
  project_tag       = var.project_tag
}

module "routes" {
  source = "./environment/routes"

  vpc_id                 = module.vpc.vpc_id
  aws_public_subnet_1_id = module.network.public_subnet_1_id
  aws_public_subnet_2_id = module.network.public_subnet_2_id
  aws_public_subnet_3_id = module.network.public_subnet_3_id
  project_tag            = var.project_tag
  public_cidrblock       = var.public_cidrblock
}

module "security" {
  source = "./environment/security"

  vpc_id            = module.vpc.vpc_id
  public_cidr_block = var.public_cidrblock
  project_tag       = var.project_tag
}
