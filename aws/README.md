# Getting Started
Postgres Deployment scripts are an easy way to deploy Postgres and EDB Tools at no charge. It is a contribution by the EDB team members which can help people explore both Postgres and EDB tools. Users can interact via the git repository comments section. Feel free to leave comments there. However, these scripts are not officially supported by the EnterpriseDb Team.

EnterpriseDb has the largest base of PostgreSQL experts available.

Learn more about [Professional Support] (https://www.enterprisedb.com/services/ongoing-postgresql-help/postgresql-technical-support)

The intention of this repository is as an introductory self starting guide.

Before starting to delve into this repository, it is best to get familiar with the steps in the deployment process towards Amazon Web Services.

## The overall process consists of the following steps:

1. Set up Software Prerequisites
   * Linux based Operating System
   * Package dependencies installation are accomplished via bash script
   * AWS CLI v2 installed via bash script
   * Requires configuration of AWS Command Line Interface v2 for authentication
2. Configure AWS CLI v2 with credentials
3. Create Cloud Infrastructure Prerequisites Resources
   * Performed by Terraform scripts in ```01-terraform``` folder
4. Setup Postgres or EnterpriseDB Postgres Advanced Server
   * Performed by Ansible scripts in Ansible Galaxy downloaded collection: ```edb_devops.edb_postgres```
5. Execute SQL Scripts
   * Performed by Ansible scripts in ```02-sqlexec``` folder

----
### Software Prerequisites
1. Terraform installed and configured
2. Ansible installed and configured

**Require Installation**

* [Terraform Installation]  (https://learn.hashicorp.com/terraform/getting-started/install.html)
  ![Terraform 0.13 Installation](demos/Terraform_0.13_Installation.gif)

* [Ansible Installation] (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

### Prerequisites Setup
##### Dependencies
1. Vendor Cloud SDK ( AWS, GCP or Azure )
2. Packages: curl and wget
1. Terraform >= 0.13
2. Ansible >= 2.9

### Steps

* Items to consider:
  * The Operating Systems Images ( CentOS7 and RHEL7 ) are supported across the following Google Cloud Locations: centralus, eastus, eastus2, westus, westcentralus, westus2, northcentralus and southcentralus
  * A minimum of 3 instances is recommended

* The bash scripts utilized in the scripts have been tested on:
  * Red Hat 7
  * CentOS 7
  * Debian 9
  * Ubuntu 20.04

* Create your AWS Key Pair File or make it available for its reference
  ![Create AWS Key Pair File](demos/AWS_Key_Pair_File_Generation.gif)
    
* Download ```postgres-deployment``` github repo by clicking on the green **Code** button followed by clicking the **Download Zip** link

* Extract the zip file to a desired destination

* Copy the ```postgres-deployment.zip``` file to the desired target directory
  
* Extract the zip file to a desired destination by utilizing Archive Manager or by: typing ```unzip postgres-deployment.zip``` and pressing the **Enter** button
 
* Open the ```Terminal``` command line

* Navigate to the extracted folder location and type: ```cd postgres-deployment/aws``` finishing with pressing the **Enter** button

* Type: ```./edb-deployment.sh``` and execute the bash script by pressing the **Enter** button. The subcommands below will be listed as options:
```
edb-deployment [aws-server|postgres] [OPTION]...

EDB deployment script for aws

Subcommands:
    aws-server     [create|destroy]  PROJECT_NAME
    postgres       install           PROJECT_NAME

Other Options:
    -h, --help Display help and exit
```


* Type: ```./edb-deployment aws-server destroy PROJECT_NAME``` and execute the bash script by pressing the **Enter** button.
  ![Removed Created AWS Resources](demos/AWS_EDB-Delete.gif)

### Manual Setup
* The scripts below are described in their execution order for a manual setup and located in the ```lib_sh``` directory:
  * keygen.sh - Removes and creates the SSH Keys
  ![Generate SSH Keys](demos/KeyGen.gif)
  * prereqs.sh - Installs dependent packages
  ![Install Package Dependencies](demos/AWS_PreReqs_Setup_v2.gif)
  * aws-cli.sh - Installs Google Cloud SDK and initiates the Google Cloud Credentials
   Configuration
   The results should be similar as the video below:
  ![AWS CLI v2 Installation](demos/AWS_CLI_v2_Installation.gif)
  * Configure the AWS CLI by typing: ```AWS configure``` and pressing **Enter** button
  ![AWS CLI v2 Configuration](demos/AWS_CLI_v2_Configuration.gif)
  
### Execute SQL Statements on Postgres Cluster
##### Dependencies
1. Ansible
2. Cloud Infrastructure Prerequisites
3. Previously setup and configured Postgres or EnterpriseDB Postgres Advanced Server Instances

**Steps**

* Navigate to the **02-sqlexec** folder

* Refer to the example files: ```hosts.yml``` and ```playbook.yml``` located in the ```02-sqlexec``` directory
  ![SQLExec](demos/SQLExec.gif)
