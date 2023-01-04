variable "region" {
  description = "AWS region"
  type        = string
}

variable "kEnvironment" {
  description = "Environment"
}

variable "kProject" {
  description = "Project Name"
}

variable "kClusterName" {
  description = "k8s Cluster Name"
}

variable "kNodeGroup1CidrBlock" {
  description = "Node Group 1 Cidr Block"
}

variable "kNodeGroup2CidrBlock" {
  description = "Node Group 2 Cidr Block"
}

variable "kVpcName" {
  description = "VPC Name"
}

variable "kVpcCidrBlock" {
  description = "VPC Cidr Block"
}

variable "kPrivateSubnet1" {
  description = "Private Subnet 1"
}

variable "kPrivateSubnet2" {
  description = "Private Subnet 2"
}

variable "kPrivateSubnet3" {
  description = "Private Subnet 3"
}

variable "kPublicSubnet1" {
  description = "Public Subnet 1"
}

variable "kPublicSubnet2" {
  description = "Public Subnet 2"
}

variable "kPublicSubnet3" {
  description = "Public Subnet 3"
}

variable "kSecurityGroupWorkerGroup1" {
  description = "Security Group Worker Group 1 Name"
}

variable "kSecurityGroupWorkerGroup2" {
  description = "Security Group Worker Group 2 Name"
}

variable "kClusterVersion" {
  description = "Cluster Version"
}

variable "kClusterAMIType" {
  description = "Cluster AMI Type"
}

variable "kWorkerGroup1InstanceType" {
  description = "Worker Group 1 Instance Type"
}

variable "kWorkerGroup2InstanceType" {
  description = "Worker Group 2 Instance Type"
}

variable "kNodeGroup1Name" {
  description = "Node Group 1 Name"
}

variable "kNodeGroup2Name" {
  description = "Node Group 2 Name"
}

variable "kClusterNodeGroup1MinimumSize" {
  description = "Node Group 1 Minimum Size"
}

variable "kClusterNodeGroup1MaximumSize" {
  description = "Node Group 1 Maximum Size"
}

variable "kClusterNodeGroup1DesiredSize" {
  description = "Node Group 1 Desired Size"
}

variable "kClusterNodeGroup2MinimumSize" {
  description = "Node Group 2 Minimum Size"
}

variable "kClusterNodeGroup2MaximumSize" {
  description = "Node Group 2 Maximum Size"
}

variable "kClusterNodeGroup2DesiredSize" {
  description = "Node Group 2 Desired Size"
}

variable "kSecurityGroupWorkerGroup1FromPort" {
  description = "Security Group Worker Group 1 From Port"
}

variable "kSecurityGroupWorkerGroup1ToPort" {
  description = "Security Group Worker Group 1 To Port"
}

variable "kSecurityGroupWorkerGroup2FromPort" {
  description = "Security Group Worker Group 2 From Port"
}

variable "kSecurityGroupWorkerGroup2ToPort" {
  description = "Security Group Worker Group 2 To Port"
}

variable "kSecurityGroupWorkerGroup1Protocol" {
  description = "Security Group Worker Group 1 Protocol"
}

variable "kSecurityGroupWorkerGroup2Protocol" {
  description = "Security Group Worker Group 2 Protocol"
}
