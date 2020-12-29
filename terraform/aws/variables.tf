# Most frequently accessed settings
# OS
variable "os" {
  # Options: 'CentOS7' or 'RHEL7'
  default = "CentOS7"
}

variable "ami_id" {
  # CentOS7 AMI ID
  default = "ami-0bc06212a56393ee1"
}

# Region
variable "aws_region" {
  default = "us-west-2"
}

# Instance Count
variable "instance_count" {
  default = 3
}

# PEM Instance Count
variable "pem_instance_count" {
  default = 0
}

# Synchronicity
variable "synchronicity" {
  default = "asynchronous"
}

# Ansible Yaml PEM Inventory Filename
variable "ansible_pem_inventory_yaml_filename" {
  default = "pem-inventory.yml"
}

# Ansible Yaml Inventory Filename
variable "ansible_inventory_yaml_filename" {
  default = "inventory.yml"
}

# OS CSV Filename
variable "os_csv_filename" {
  default = "os.csv"
}

# Ansible Add Hosts Filename
variable "add_hosts_filename" {
  type    = string
  default = "add_host.sh"
}

# Instance

# Type
variable "instance_type" {
  description = "The type of instances to create."
  # Enter AWS Instance type like t2.micro, t3.large, c4.2xlarge m5.2xlarge etc....
  # instance_type = "t2.micro"
  # instance_type = "t3.large"
  # instance_type = "c4.2xlarge"
  # instance_type = "m5.2xlarge"
  default = "c5.2xlarge"
  type    = string
}

# Instance Volume Type
variable "instance_volume_type" {
  # Enter AWS Instance volume type like io1, io2, gp2
  # instance_volume_type = "gp2"
  # instance_volume_type = "io1"
  # instance_volume_type = "io2"
  default = "gp2"
  type    = string
}

# Instance Volume IOPS
variable "instance_volume_iops" {
  # Enter AWS Instance volume iops only for io1 or io2
  default = "250"
  type    = string
}

# Instance Volume Size
variable "instance_volume_size" {
  # Enter AWS Instance volume size in GB
  default = "100"
  type    = string
}

# EBS
# EBS Volume Count
variable "ebs_volume_count" {
  # default = 5
  default = 0
}

# EBS volume prefix name
variable "ebs_volume_name" {
  description = "The name of the EBS volume"
  default     = "/dev/sdc"
}

# EBS Volume disk types
variable "ebs_volume_type" {
  # Enter AWS Instance volume type like io1, io2, gp2
  # instance_volume_type = "gp2"
  # instance_volume_type = "io1"
  # instance_volume_type = "io2"
  default = "gp2"
  type    = string
}

# EBS Volume disk size
variable "ebs_volume_size" {
  description = "The size of the EBS Volume Disk Size in GB."
  default     = 100
}

# EBS Volume disk iops
variable "ebs_volume_iops" {
  description = "The iops for volume."
  default     = 250
}

# EBS Volume disk encryption
variable "ebs_volume_encryption" {
  description = "The encryption type for volume."
  default     = "false"
}

# VPC
variable "public_cidrblock" {
  description = "Public CIDR block"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_cidr_block" {
  description = "CIDR Block for the VPC"
  default     = "10.0.0.0/16"
}

# Name of the Cluster
variable "cluster_name" {
  description = "The name to the cluster"
  default     = "awscmncl"
  type        = string
}

# IAM User Name
variable "user_name" {
  description = "Desired name for AWS IAM User"
  type        = string
  default     = "awscmncl-edb-iam-postgres"
}

# IAM Force Destroy
variable "user_force_destroy" {
  description = "Force destroying AWS IAM User and dependencies"
  type        = bool
  default     = true
}

# SSH
variable "ssh_keypair" {
  description = "The SSH key pair name"
  type        = string
  # Enter SSH key pair name without extension
  # Example: "<nameofkeypairfile>"
  default = ""
}

variable "ssh_key_path" {
  description = "SSH private key path from local machine"
  type        = string
  # Example: "~/mypemfile.pem"
  default = ""
}

variable "full_private_ssh_key_path" {
  description = "SSH private key path from local machine"
  type        = string
  # Example: "~/mypemfile.pem"
  default = ""
}

variable "root_user" {
  type    = string
  default = "centos"
}
