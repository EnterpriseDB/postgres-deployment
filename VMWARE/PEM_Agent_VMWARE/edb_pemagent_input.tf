###### Mandatory Fields in this config file #####
### ssh_user   
### ssh_password
### db_password
### pem_web_ui_password
#############################################
### Optional Field in this config file
### EDB_Yum_Repo_Username }  Mandatory only for dbengine pg10,11,12
### EDB_Yum_Repo_Password }
###########################################

module "edb-pem-agent" {
  # The source module used for pem agent installation and configuration.

  source = "./EDB_PEM_AGENT_VMWARE"
  
  # Enter EDB yum repository credentials for usage of any EDB tools. 

  EDB_Yum_Repo_Username  = ""

  # Enter EDB yum repository credentials for usage of any EDB tools.  

  EDB_Yum_Repo_Password = ""

  # Enter ssh log in user

  ssh_user = ""

  # Provide path of ssh password to connect vm

  ssh_password = ""
 
  # Enter optional database (DB) User, leave it blank to use default user else enter desired user. 
 
  db_user = ""
  
  # Enter DB password of remote server.

  db_password = ""

  # Enter Password of PEM WEB UI 
 
  pem_web_ui_password = ""  
}  

