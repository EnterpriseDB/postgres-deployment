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


variable "ssh_user" {
  description = "The username to use when connect to the VM."
  type        = string
  default     = "root"
}

variable "ssh_password" {
  description = "ssh password to connect vm."
  type        = string
}


variable "db_password" {
  description = "Enter PEM DB password"
  type        = string
}


variable "pem_web_ui_password" {
  description = "Enter password of pem server WEB UI"
  type        = string
}

variable "db_user" {
  description = "Provide custom DB user name"
  type        = string
}




