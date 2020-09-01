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
   * GCP SDK installed via bash script
   * Requires configuration of GCP SDK for authentication
2. Configure GCP SDK with credentials
3. Create your SSH Private and Public Key with proper permissions
4. Create Cloud Infrastructure Prerequisites Resources
   * Performed by Terraform scripts in ```01-terraform``` folder
5. Setup Postgres or EnterpriseDB Postgres Advanced Server
   * Performed by Ansible scripts in Ansible Galaxy downloaded collection: ```edb_devops.edb_postgres```

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

* Download your Google Cloud JSON File Credentials
  * Navigate to the Google Cloud Platform Console
  * Click on **IAM & Admin** -> **Service Accounts**
  * Select the Service Account -> Click the ellipsis menu button -> **Create key**
  * Select the Key Type: **JSON** --> **Create Button**
  * Rename the downloaded JSON Credentials File to something relatively easy to type
  ![GCP JSON File Credentials](demos/Google_Cloud_SDK_Generate_Credentials_JSON_File.gif)

* Download ```postgres-deployment``` github repo by clicking on the green **Code** button followed by clicking the **Download Zip** link

* Copy the ```postgres-deployment.zip``` file to the desired target directory
  
* Extract the zip file to a desired destination by utilizing Archive Manager or by: typing ```unzip postgres-deployment.zip``` and pressing the **Enter** button

* Open the ```Terminal``` command line

* Navigate to the extracted folder location and type: ```cd postgres-deployment/gcp``` finishing with pressing the **Enter** button

* Type: ```./edb-setup.sh``` and execute the bash script by pressing the **Enter** button
  * The results should be similar as the video below:
  ![GCP Complete Setup](demos/GCP_EDB-Setup.gif)

* Type: ```./edb-delete.sh <projectfilename>.txt``` and execute the bash script by pressing the **Enter** button. A file with ```.txt``` was created with the named indicated in one of the parameters being prompted.
  ![Removed Created Google Cloud Resources](demos/GCP_EDB-Delete.gif)

### Manual Setup

* The scripts below are described in their execution order for a manual setup:
  * keygen.sh - Removes and creates the SSH Keys
  ![Generate SSH Keys](demos/KeyGen.gif)
  * prereqs.sh - Installs dependent packages
  ![Install Package Dependencies](demos/GCP_PreReqs_Setup_v2.gif)
  * gcp-sdk.sh - Installs Google Cloud SDK and initiates the Google Cloud Credentials
   Configuration
  ![Install Google Cloud SDK](demos/GCP_SDK_Installation_v2.gif)
  * pre-setup.sh - Creates the Infrastructure
  ![Deploy Resources in Google Cloud](demos/GCP_PreReqs_Setup_v2.gif)
  * pg-setup.sh - Deploys Postgres or EDB Postgres Advanced Server
  ![Install and Configure Postgres or EPAS](demos/GCP_PGSetup_v2.gif)
  * edb-delete.sh - Deletes the Infrastructure
  ![Removed Created Google Cloud Resources](demos/GCP_EDB-Delete.gif)
* A file named ```project_template.txt``` is provided that can be utilized to provide configuration details and be passed as a file to:
  * ```pre-setup.sh <projectname>.txt```
  * ```edb-delete.sh <projectname>.txt```
