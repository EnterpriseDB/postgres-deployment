###### Mandatory Fields in this config file #####
### ssh_password
### notification_email_address
### efm_role_password
#############################################

### Optional Field in this config file
### EDB_Yum_Repo_Username } Mandatory if selecting dbengine pg(all version) 
### EDB_Yum_Repo_Password }
### db_user
###########################################

module "efm-db-cluster" {
  # The source module used for creating clusters.
  
  source = "./EDB_EFM_VMWARE"
  
  # Enter EDB yum repository credentials for usage of any EDB tools.

  EDB_Yum_Repo_Username = ""

  # Enter EDB yum repository credentials for usage of any EDB tools.

  EDB_Yum_Repo_Password = ""

  # Provide ssh password. 

  ssh_password = ""

  # Enter optional database (DB) User, leave it blank to use default user else enter desired user.

  db_user = ""

  # Enter EFM notification email.
 
  notification_email_address = ""

  # Enter EFM role password.

  efm_role_password = ""

}  
