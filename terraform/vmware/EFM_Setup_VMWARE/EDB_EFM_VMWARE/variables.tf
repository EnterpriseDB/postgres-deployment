variable "EDB_Yum_Repo_Username" {
  description = "Enter EDB yum repo login user name"
  default     = ""
  type        = string

}

variable "EDB_Yum_Repo_Password" {
  description = "Enter EDB yum repo login password"
  default     = ""
  type        = string
}


variable "ssh_password" {
  description = "ssh password to connect VM."
  type        = string
}

variable "notification_email_address" {
  description = "Enter email address where EFM notification will go"
  type        = string
}

variable "efm_role_password" {
  description = "Enter password for DB role created from EFM operation"
  type        = string
}



variable "db_user" {
  description = "Provide DB user if you are not using default DB user"
  type        = string
  default     = ""
}

