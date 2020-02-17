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

variable "vpc_id" {
   type    = string
   description = "Enter VPC-ID"
   default     = ""
}
  
variable "subnet_id" {
  type        = string
  description = "The subnet-id to use for instance creation."
}



variable "instance_type" {
  description = "The type of instances to create."
  default     = "c4.xlarge"
  type        = string
}

variable "custom_security_group_id" {
  description = "Security group to assign to the instances. Example: 'sg-12345'."
  type        = string
  default     = ""
}

variable "iam-instance-profile" {
  description = "IAM role name attaching to the instance"
  default = ""
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
