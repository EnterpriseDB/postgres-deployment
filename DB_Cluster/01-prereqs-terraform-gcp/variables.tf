variable "credentials" {
  default = "~/credentials/account.json"
}

variable "project_name" {
  default = "performance-engineering-268015"
}

variable "prefix" {
  default = "edb-prereq"
}

variable "instance_count" {
  default = 3
}

variable "instance_name" {
  default = "edb-vm"
}

variable "network_name" {
  default = "edb-prereq-network"
}

variable "subnetwork_region" {
  default = "us-west1"
}

variable "subnetwork_name" {
  #default = "${var.network_name}-subnetwork-${var.subnetwork_region}"
  default = "edb-prereq-network-subnetwork-us-west1"
}

variable "ip_cidr_range" {
  default = "10.0.0.0/16"
}

variable "source_ranges" {
  default = "0.0.0.0/0"
}

variable "vm_type" {
  default = "f1-micro"
}

variable "os" {
  #default = "centos-7-v20170816"
  #default = "centos-7-v20200403
  default = "rhel-7-v20200403"
}

variable "ssh_user" {
  default = "centos"
}

variable "ssh_key_location" {
  default = "~/.ssh/id_rsa.pub"
}
