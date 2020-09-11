variable "EDB_yumrepo_username" {
  description = "yum repo user name"
  default     = ""
  type        = string
}

variable "EDB_yumrepo_password" {
  description = "yum repo user password"
  default     = ""
  type        = string
}



variable "ssh_user" {
  description = "The username who can connect to the VM."
  type        = string
  default     = "centos"
}



variable "ssh_password" {
  description = "The SSH password"
  type = string
}

variable "dcname" {
  description = "vmware vsphere dcname"
  type = string
}

variable "db_password" {
   description = "Enter DB password of your choice"
   type = string
}

variable "cpucore" {
    description = "Enter number of cpu core for your vm"
    type = string
    default = "2"
}

variable "ramsize" {
    description = "Enter RAM size for your new VM"
    type = string
    default = "1024"
}

variable "template_name" {
    description = "Enter template name of centos 7"
    type = string
}

variable "datastore" {
     description = "Provide Datastore name"
     type = string
}

variable "compute_cluster" {
     description = "Provide Compute cluster name"
     type = string
}

variable "network" {
     description = "Provide Network name"
     type = string
}

