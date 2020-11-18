variable "credentials" {
  # Example: "~/accounts.json"
  default = ""
}

variable "project_name" {
  default = ""
}


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

variable "subnetwork_region" {
  # Options: 'us-central1','us-east1', 'us-east4', 'us-west1', 'us-west2', 'us-west3' and 'us-west4'
  default = ""
}

variable "subnetwork_name" {
  # Must have network_name tag as a prefix
  default = "edb-network-subnetwork"  
}

variable "ip_cidr_range" {
  default = "10.0.0.0/16"
}

variable "source_ranges" {
  default = "0.0.0.0/0"
}

variable "vm_type" {
  # Better suite for Replication and EFM
  #default = "f1-micro"
  # Better suited for PEM
  default = "e2-standard-2"
}

variable "os" {
  default = "centos-7-v20170816"
  #default = "centos-7-v20200403
  #default = "rhel-7-v20200403"
}

variable "ssh_user" {
  default = "centos"
}

variable "ssh_key_location" {
  # Example: "~/.ssh/id_rsa.pub"
  default = ""
}

# Ansible Inventory Filenames
# Ansible Yaml PEM Inventory Filename
variable "ansible_pem_inventory_yaml_filename" {
  default = "pem-inventory.yml"
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

# Tags
variable "prefix" {
  default = "edb"
}

variable "instance_name" {
  default = "edb-vm"
}

variable "network_name" {
  default = "edb-network"
}
