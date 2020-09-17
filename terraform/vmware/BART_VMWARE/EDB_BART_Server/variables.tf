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

variable "dcname" {
  description = "vmware vsphere datacenter name"
  default     = ""
  type        = string
}

variable "ssh_user" {
  description = "The user who can login and perform this operations."
  type        = string
  default     = "root"
}

variable "ssh_password" {
  description = "SSH password to connect vm"
  type        = string
}

variable "cpucore" {
  description = "Enter number of cpu core for your vm"
  type        = string
  default     = "2"
}

variable "ramsize" {
  description = "Enter RAM size for your new VM"
  type        = string
  default     = "1024"
}

variable "template_name" {
  description = "Enter template name of base centos 7"
  type        = string
}

variable "datastore" {
  description = "Provide Datastore name"
  type        = string
}

variable "compute_cluster" {
  description = "Provide Compute cluster name"
  type        = string
}

variable "network" {
  description = "Provide Network name"
  type        = string
}


variable "db_password" {
  description = "Enter DB password of remote server"
  type        = string
}

variable "retention_period" {
  description = "Enter retension period"
  type        = string
  default     = ""
}

variable "db_user" {
  description = "Provide Db user name"
  type        = string
}

variable size {
  description = "Provide size of additional disk"
  type        = number
}
