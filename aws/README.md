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

* Download ```postgres-deployment``` github repo by clicking on the green **Code** button followed by clicking the **Download Zip** link

* Extract the zip file to a desired destination
 
* Open the ```Terminal``` command line

* Navigate to the extracted folder location and type: ```cd postgres-deployment/aws/01-terraform-ansible``` finishing with pressing the **Enter** button

* Items to consider:
  * The Operating Systems Images ( CentOS7 and RHEL7 ) are supported across the following AWS Regions: us-east-1, us-east-2, us-west-1 and us-west-2
  * A minimum of 3 instances is recommended

* Type: ```./00-prereqs.sh``` and execute the bash script by pressing the **Enter** button

* Type: ```./01-aws-cli.sh``` and execute the bash script by pressing the **Enter** button. The results should be similar as the video below:
  ![AWS CLI v2 Installation](demos/AWS_CLI_v2_Installation.gif)

* Configure the AWS CLI by typing: ```AWS configure``` and pressing **Enter** button
  ![AWS CLI v2 Configuration](demos/AWS_CLI_v2_Configuration.gif)

* Type: ```./02-pre-setup.sh``` and execute the bash script by pressing the **Enter** button and provide the answers to the prompts. The script will await until the instances are available.

* **Allow for the instances creation to complete ( times will vary depending on amount of instances and instance types ). Once completed, proceed to the next step**

* Type: ```./03-pg-setup.sh``` and execute the bash script by pressing the **Enter** button and provide the answers to the prompts

### Execute SQL Statements on Postgres Cluster
##### Dependencies
1. Ansible
2. Cloud Infrastructure Prerequisites
3. Previously setup and configured Postgres or EnterpriseDB Postgres Advanced Server Instances

**Steps**

* Navigate to the **02-sqlexec** folder

* Refer to the example files: ```hosts.yml``` and ```playbook.yml``` located in the ```02-sqlexec``` directory
  ![SQLExec](demos/SQLExec.gif)

