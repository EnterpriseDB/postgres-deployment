module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = var.kVpcName

  cidr = var.kVpcCidrBlock
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = [var.kPrivateSubnet1, var.kPrivateSubnet2, var.kPrivateSubnet3]
  public_subnets  = [var.kPublicSubnet1, var.kPublicSubnet2, var.kPublicSubnet3]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}
