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
  default = ""
  type = string
}

variable "ssh_user" {
  description = "The username who can connect to the VM."
  type        = string
  default     = "root"
}

variable "ssh_password" {
  description = "SSH password to connect VM"
  type = string
}



variable "replication_type" {
   description = "Select replication type asynchronous or synchronous"
   type = string
   default = "asynchronous"
}

variable "replication_password" {
   description = "Enter replication password of your choice"
   type = string
}

variable "db_user" {
   description = "Enter optional DB user name"
   type = string
}

variable "db_password" {
   description = "Enter custom DB password"
   type = string
   default = "postgres"
}  

variable "cpucore" {
    description = "Enter number of cpu core for your VM"
    type = string
    default = "2"
}

variable "ramsize" {
    description = "Enter RAM size for your new VM"
    type = string
    default = "1024"
}

variable "template_name" {
    description = "Enter template name of base centos 7"
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

variable "efm_role_password" { 
   description = "Provide efm role password"
   type = string
}

variable "notification_email_address" {
   description = "Provide notification email address"
   type = string
}

variable "db_password_pem" {
   description = "Provide pem server DB password"
   type = string
}

variable "cpucore_pem" {
    description = "Enter number of cpu core for your VM"
    type = string
    default = "2"
}

variable "ramsize_pem" {
    description = "Enter RAM size for your new VM"
    type = string
    default = "1024"
}

variable "cpucore_bart" {
    description = "Enter number of cpu core for your VM"
    type = string
    default = "2"
}

variable "ramsize_bart" {
    description = "Enter RAM size for your new VM"
    type = string
    default = "1024"
}

variable "retention_period" {
   description = "Enter retension period"
   type = string
   default = ""
}

variable size {
   description = "Provide size of additional disk"
   type = number
}

variable "cluster_name" {
   description = "Provide clustername"
   type = string
} 

