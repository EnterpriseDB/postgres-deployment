variable "EDB_yumrepo_username" {
  description = "yum repo user name"
  default     = ""
  type        = string
}

variable "dcname" {
 description = "Provide vmware vsphere datacenter name"
 default = ""
 type = string 
}


variable "EDB_yumrepo_password" {
  description = "yum repo user password"
  default     = ""
  type        = string
}

variable "cpucore" {
   type    = string
   description = "Enter number of CPU core for virtual machine"
   default     = "2"
}
  
variable "ramsize" {
  type        = string
  description = "Enter RAM size to allocate for new virtual machine"
  default = "1024"
}


variable "ssh_user" {
  description = "The username who can connect to the VM."
  type        = string
  default     = "centos"
}

variable "ssh_password" {
  description = "Provide ssh password to login"
  default     = ""
  type        = string
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


variable "notification_email_address" {
   description = "Enter email address where EFM notification will go"
   type = string
}

variable "efm_role_password" {
   description = "Enter password for DB role created from EFM operation"
   type        = string
}

variable "db_password" {
   description = "Enter DB password"
   type = string
}


variable "pem_web_ui_password" {
   description = "Enter password of pem server WEB UI"
   type        = string
}

variable "template_name" {
   description = "Provide template name for base centos 7"
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
