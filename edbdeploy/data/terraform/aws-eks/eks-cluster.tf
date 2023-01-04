module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = local.cluster_name
  cluster_version = var.kClusterVersion

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = var.kClusterAMIType

    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false
  }

  eks_managed_node_groups = {
    one = {
      name = var.kNodeGroup1Name

      instance_types = [var.kWorkerGroup1InstanceType]

      min_size     = var.kClusterNodeGroup1MinimumSize
      max_size     = var.kClusterNodeGroup1MaximumSize
      desired_size = var.kClusterNodeGroup1DesiredSize

      pre_bootstrap_user_data = <<-EOT
      echo 'foo bar'
      EOT

      vpc_security_group_ids = [
        aws_security_group.node_group_one.id
      ]
    }

    two = {
      name = var.kNodeGroup2Name

      instance_types = [var.kWorkerGroup2InstanceType]

      min_size     = var.kClusterNodeGroup2MinimumSize
      max_size     = var.kClusterNodeGroup2MaximumSize
      desired_size = var.kClusterNodeGroup2DesiredSize

      pre_bootstrap_user_data = <<-EOT
      echo 'foo bar'
      EOT

      vpc_security_group_ids = [
        aws_security_group.node_group_two.id
      ]
    }
  }
}
