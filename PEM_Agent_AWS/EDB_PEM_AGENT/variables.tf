variable "EDB_Yum_Repo_Username" {
   description = "Enter EDB yum repo login user name"
   default     = ""
   type = string
   
}

variable "EDB_Yum_Repo_Password" {
   description = "Enter EDB yum repo login password"
   default     = ""
   type = string
}



variable "db_password" {
   description = "Enter PEM DB password"
   type = string
}


variable "pem_web_ui_password" {
   description = "Enter password of pem server WEB UI"
   type        = string
}

variable "db_user" {
   
   description = "Enter DB username if you have changed it from default"
   type = string
}
 
 

