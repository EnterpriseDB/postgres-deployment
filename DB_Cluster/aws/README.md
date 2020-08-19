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
   * Performed by Terraform scripts in ```01-prereqs-terraform``` folder
4. Setup Postgres or EnterpriseDB Postgres Advanced Server
   * Performed by Ansible scripts in Ansible Galaxy downloaded collection: ```edb_devops.edb_postgres```
5. Execute SQL Scripts
   * Performed by Ansible scripts in ```02-sqlexec``` folder

----

### Contents of this Directory

* The contents of this directory are:
  * ```01-terraform-ansible``` - Contains a deployment that utilizes Terraform for Infrastructure and Ansible for Configuration.
