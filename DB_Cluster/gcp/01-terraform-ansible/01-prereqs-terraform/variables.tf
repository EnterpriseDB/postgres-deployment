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

variable "subnetwork_region" {
  # Options: 'us-central1','us-east1', 'us-east4', 'us-west1', 'us-west2', 'us-west3' and 'us-west4'
  default = ""
}

variable "subnetwork_name" {
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
# Ansible Yaml Inventory Filename
variable "ansible_inventory_yaml_filename" {
  default = "inventory.yml"
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

# Tags
variable "prefix" {
  default = "edb-prereq"
}

variable "instance_name" {
  default = "edb-vm"
}

variable "network_name" {
  default = "edb-prereq-network"
}
