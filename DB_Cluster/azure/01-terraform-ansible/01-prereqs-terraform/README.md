# Getting Started
Postgres Deployment scripts are an easy way to deploy Postgres and EDB Tools at no charge. It is a contribution by the EDB team members which can help people explore both Postgres and EDB tools. Users can interact via the git repository comments section. Feel free to leave comments there. However, these scripts are not officially supported by the EnterpriseDb Team.

EnterpriseDB has the largest base of PostgreSQL experts available.

Learn more about [Professional Support] (https://www.enterprisedb.com/services/ongoing-postgresql-help/postgresql-technical-support)

The intention of this repository is as an introductory self starting guide for setting up the prerequisites needed to install and configure Postgres or EnterpriseDB Postgres Advanced Server in Azure.

Before starting to delve into this repository, it is best to get familiar with the steps in the deployment process towards Azure.

## The overall process consists of the following steps:

1. Set up Software Prerequisites
   * Accomplished manually
   * Requires configuration of Azure Command Line Interface for authentication towards Azure
   * [Installing Azure CLI]
(https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)
   * [Terraform Installation]  (https://learn.hashicorp.com/terraform/getting-started/install.html)
   * Download the Code for this repository by navigating to the top of this page and clicking on: **Code** Green Button -> **Download ZIP** Link
   * Type: ```edb-tf-azure``` and press **Enter**

----
### Supported Operating Systems
* Centos 7
* RedHat 7

----
### Software Prerequisites
1. Azure CLI
2. Terraform >= 0.13

**Require Manual Installation**
* Installing Azure CLI
  ![Installing Azure CLI](tutorials/Azure_CLI_Installation.gif)
* Installation of Terraform 0.13 
  ![Terraform 0.13 Installation](tutorials/Terraform_0.13_Installation.gif)
* Download the Code for this repository by navigating to the top of this page and clicking on: **Code** Green Button -> **Download ZIP** Link
* Type: ```edb-tf-azure``` and press **Enter**

----
### Prerequisites Setup and configuration
##### Dependencies
1. Azure CLI - For authenticating into Azure
2. Download the Code for this repository by navigating to the top of this page and clicking on: **Code** Green Button -> **Download ZIP** Link
3. Type: ```edb-tf-azure``` and press **Enter**
4. Terraform

----
### Prerequisites Setup

**Steps**

* Download the Code for this repository by navigating to the top of this page and clicking on: **Code** Green Button -> **Download ZIP** Link

* Type: ```edb-tf-azure``` and press **Enter**
   
* Terraform must be initialized

* Set variables in the **```variables.tf```** file according to your desired configuration

* Variables to set:

   * ```azure_location``` - Location for the resources to be created
   * ```ssh_key_path``` - Location for previously created public key
   * ```instance_count``` - Start at ```1``` and create one VM. Once completed change the ```instance_count``` to the **```3```** and perform a **terraform apply**
   * ```publisher``` - Image publisher, examples: 'OpenLogic' and 'RedHat'
   * ```offer``` - Operating System, examples: 'Centos' and 'RHEL'
   * ```sku``` - Operating System version, examples: '7.7' and '7.8'

* Review the naming conventions utilized in the **```variables.tf```** file and update accordingly

* Before applying the changes you can preview those changes with **terraform plan**

* Create resources in Account with **terraform apply**

* The variables listed above must be provided when the **terraform plan** or **terraform apply** command are executed

Once the terraform apply has completed you should see a list resources under your ```Resource Group``` that resemble the list below:
* 1 Resource Group in your Azure account
* 1 Subnet
* 1 Public IP
* 1 Public NIC
* 1 Security Group with Rules
* 1 Virtual Network
* 1 Storage Account
* 1 Storage Container for Virtual Machines
* 1 Virtual Machine
* 1 Virtual Machine Disk


**Terraform Commands**

Initialize terraform.

```
$ terraform init
```

Assess what resources will be created with this command.

```
$ terraform plan
```

Create the resources.

```
$ terraform apply
```

Verify which resources were created.

```
$ terraform show
```

To destroy resources recently created.

```
$ terraform destroy
```

----
### Verify which resources were created
1. Login into the [Azure Portal]  (https://portal.azure.com)
2. Locate and click on the **Resource Group** recently created
3. View the Resources created and contained with the **Resource Group**
