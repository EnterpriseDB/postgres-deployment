resource "aws_security_group" "node_group_one" {
  name_prefix = var.kSecurityGroupWorkerGroup1
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = var.kSecurityGroupWorkerGroup1FromPort
    to_port   = var.kSecurityGroupWorkerGroup1ToPort
    protocol  = var.kSecurityGroupWorkerGroup1Protocol

    cidr_blocks = [
      var.kNodeGroup1CidrBlock,
    ]
  }
}

resource "aws_security_group" "node_group_two" {
  name_prefix = var.kSecurityGroupWorkerGroup2
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = var.kSecurityGroupWorkerGroup2FromPort
    to_port   = var.kSecurityGroupWorkerGroup2ToPort
    protocol  = var.kSecurityGroupWorkerGroup2Protocol

    cidr_blocks = [
      var.kNodeGroup2CidrBlock,
    ]
  }
}
