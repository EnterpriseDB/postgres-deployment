# Getting Started
Before starting to setup the Postgres Cluster, it is best to get familiar with the steps in the deployment process towards Amazon Web Services.

## The overall process consists of the following steps:

1. Set up Software Prerequisites
   * Accomplished manually
   * Requires configuration of AWS Command Line Interface for authentication towards AWS
   * [Configuring the AWS CLI]
(https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
2. Set up AWS Prerequites resources
   * Performed by Terraform scripts in "01-prerequisites" folder
   * Performed by Terraform scripts in "02-cluster" folder
   * Perform by Ansible scripts in "03-replication" folder
3. Set up AWS EC2 Instances
4. Configure Postgres Replication on the AWS EC2 Instances

----
### Skipping Steps
* If you already have AWS resources matching the ```AWS Prerequisites``` step you can skip to the ```Setup up AWS EC2 Instances``` step.
* If you already have AWS resources matching the ```AWS Prerequisites``` step and the ```AWS EC2 Instances``` step you can skip to the ```Configure Postgres Replication on the AWS EC2 Instances``` step.

----
### Software Prerequisites
1. Terraform installed
2. Ansible installed

**Require Manual Installation**

* [Terraform Installation]  (https://learn.hashicorp.com/terraform/getting-started/install.html)

* [Ansible Installation] (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

### AWS Prerequisites Setup
##### Dependencies
1. Terraform

### Components
1. 1 VPC in your AWS account
2. Minimum of 3 Subnets with Public IP enabled
3. 1 key pair to be downloaded as a .pem file locally
4. 1 S3 bucket with a folder

**Steps**

* Terraform must be initialized

* Navigate to the **01-prereqs** folder

* Set variables in the **```variables.tf```** file

* Variables to set:

   * ```user_name``` - Name for the AWS IAM role

   * ```aws_bucket_name``` - Name for the AWS Bucket
Name

   * ```aws_bucket_folder``` - Folder Name for the target AWS S3 Bucket

   * ```public_cidrblock``` - Public CIDR Block for AWS Resources

   * ```vpc_cidr_block``` - CIDR Block for the AWS VPC

   * ```public_subnet_1_cidr_block``` - CIDR Block for the AWS Public Subnet #1

   * ```public_subnet_2_cidr_block``` - CIDR Block for the AWS Public Subnet #2

   * ```public_subnet_3_cidr_block``` - CIDR Block for the AWS Public Subnet #3

* Create resources in AWS VPC with **terraform plan** or **terraform apply**

* AWS region must be provided when the **terraform plan** or **terraform apply** command are executed

* Create a folder with a name of your choice in the recently created bucket, example: ```wal```

**Terraform Commands**

Initialize terraform.

```
$ terraform init
```

Assess what resources will be created with this command.

```
$ terraform plan
```

Create the resources in AWS.

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


### AWS EC2 Instances Setup for Postgres
#### Dependencies
1. Terraform
2. AWS Prerequisites

### Components
1. 1 VPC in your AWS account
2. Minimum of 3 Subnets with Public IP enabled
3. 1 key pair to be created and downloaded as a .pem file locally
4. 1 S3 bucket with a folder

**Steps**

* Create a key pair in the AWS EC2 Console -> Services -> EC2 -> Network & Security -> Key Pairs -> Create key pair

* Terraform must be initialized

* Navigate to the **02-cluster** folder

* Set variables in the **```edb_cluster_input.tf```** file

* Variables to set:

   * ```vpc_id``` - VPC ID for the AWS VPC

   * ```subnet_id``` - The 3 Subnet ID's created by the ```AWS Prerequisites Step```

   * ```instance_type``` - Instance Types for the target AWS EC2 Instances

   * ```s3bucket``` - AWS S3 Bucket Name and folder

   * ```ssh_keypair``` - Name of the downloaded AWS EC2 Keypair File created in the AWS Console. Excluding path and ```.pem``` extension

   * ```ssh_key_path``` - Full path of the downloaded AWS EC2 Keypair File. Must include the name of the key pair file and extension.

   * ```db_engine``` - Postgres Database Engine Version to be installed. Examples: ```epas10, epas11, epas12, pg10, pg11 or pg12```

   * ```replication_type``` - Postgres Replication to be configured: ```synchronous``` or ```asynchronous```

* Create resources in AWS VPC with **terraform plan** or **terraform apply**

**Terraform Commands**

Initialize terraform.

```
$ terraform init
```

Assess what resources will be created with this command.

```
$ terraform plan
```

Create the resources in AWS.

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

### Postgres Replication Setup
##### Dependencies
1. Ansible
2. AWS Prerequisites
3. Postgres AWS EC2 Instances

### Components
1. 1 VPC in your AWS account
2. Minimum of 3 Subnets with Public IP enabled
3. 1 key pair to be downloaded as a .pem file locally
4. 1 S3 bucket with a folder

**Steps**

* Terraform must be initialized

* Navigate to the **03-replication** folder

* Create and set parameters in the **```hosts```** file
 * Create hosts file with following content.

>master_public_ip ansible_user= ansible_ssh_private_key_file=
>slave1_public_ip ansible_user= ansible_ssh_private_key_file=
>slave2_public_ip ansible_user= ansible_ssh_private_key_file=

>Replace username and path to file with your values.

* Use below command to run ansible playbook. Make sure you are providing extra arguments.

>ansible-playbook -i hosts ./utilities/scripts/setupsr.yml --extra-vars='USER= PASS= EPASDBUSER= PGDBUSER= ip1= ip2= ip3= S3BUCKET= REPLICATION_USER_PASSWORD= DBPASSWORD= REPLICATION_TYPE= DB_ENGINE= MASTER= SLAVE1= SLAVE2='

* Variables to set:

   * ```PGDBUSER``` - Password for the Postgres Database

   * ```ip1``` - Private IP Address for the Master Instance

   * ```ip2``` - Private IP Address for the Slave #1

   * ```ip3``` - Private IP Address for the Slave #2

   * ```S3BUCKET``` - AWS S3 Bucket and folder

   * ```REPLICATION_USER_PASSWORD``` - Replication User Name

   * ```DBPASSWORD ``` - Replication User Password

   * ```REPLICATION_TYPE``` - Replication Type: ```synchronous``` or ```asynchronous```

   * ```DB_ENGINE``` - Postgres Database Engine Version to be installed. Examples: ```epas10, epas11, epas12, pg10, pg11 or pg12``

   * ```MASTER_1``` - AWS EC2 Master Public IP Address

   * ```SLAVE_1``` - AWS EC2 Slave #1 Public IP Address

   * ```SLAVE_2``` - AWS EC2 Slave #2 Public IP Address

