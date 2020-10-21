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

# Ansible Inventory Filenames
# Ansible Yaml Inventory Filename
variable "ansible_inventory_yaml_filename" {
  default = "inventory.yml"
}

# Ansible Yaml PEM Inventory Filename
variable "ansible_pem_inventory_yaml_filename" {
  default = "pem-inventory.yml"
}

# Ansible Ini Inventory Filename
variable "ansible_inventory_ini_filename" {
  default = "inventory"
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

# Instance Type
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
  default     = "tcluster"
  type        = string
}

# IAM User Name
variable "user_name" {
  description = "Desired name for AWS IAM User"
  type        = string
  default     = "tcluster-edb-iam-postgres"
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
