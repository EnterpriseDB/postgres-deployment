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

# Ansible Hosts Filename
variable "hosts_filename" {
  type    = string
  default = "hosts"
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

# VM Disks
# VM disk size
variable "vm_disk_size" {
  description = "The size of the VM Disk Size in GB."
  default = 50
}

variable "vm_disk_type" {
  # Enter VM Disk type like pd_standard or pd_ssd
  # volume_type = "pd-standard"
  # volume_type = "pd-balanced"
  # volume_type = "pd-ssd"
  default = "pd-ssd"
  type    = string
}

# Attached Disks
# Volume Count
variable "volume_count" {
  default = 5
}

# Volume disk types
variable "volume_disk_type" {
  # Enter VM volume type like pd_standard or pd_ssd
  # volume_type = "pd-standard"
  # volume_type = "pd-balanced"
  # volume_type = "pd-ssd"
  default = "pd-ssd"
  type    = string
}

# Volume disk size
variable "volume_disk_size" {
  description = "The size of the Volume Disk Size in GB."
  default = 10
}

# Volume disk iops
variable "volume_iops" {
  description = "The iops for volume."
  default = 250
}

# Volume disk encryption
variable "volume_encryption" {
  description = "The encryption type for volume."
  default = "false"
}

variable "full_private_ssh_key_path" {
  description = "SSH private key path from local machine"
  type        = string
  # Example: "~/mypemfile.pem"
  default = ""
}

variable "disk_encryption_key" {
  default = "SGVsbG8gZnJvbSBHb29nbGUgQ2xvdWQgUGxhdGZvcm0="
}