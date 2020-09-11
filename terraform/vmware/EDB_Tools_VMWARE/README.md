## Getting Started
Before using this module you need to install a few software on your local system or system from where you are going to run the Postgres deployment scripts. 

Download module from EDB git repository on your local system or machine used to deploy the script. The deployment scripts are organized based on the providers currently available. The different folders are named with provider name (eg AWS, VMWARE) at the end. For creating database clusters on VMWARE Vsphere, you need to go inside folder DB_Cluster_VMWARE.

## Prerequisites
1. Terraform installed 
2. Ansible installed
3. Centos 7 template created with gnome access.

EDB_SRSETUP_VMWARE module - automates deployment of 3 node Postgres/Enterprise Postgres cluster on VMWARE Vsphere. Based on the user input provided in the DB_Cluster_VMWARE/edb_cluster_input.tf file.

If not already done so, please update the file edb_cluster_input.tf in your favorite editor and fill all the mandatory details. Once all the parameters are provided, save the file and proceed with cluster creation steps as follows:-


Init terraform first if you have not already done so.

```
$ terraform init
```

Now run the following to create the instances and bring up the cluster.

```
$ terraform apply
```
You can check resources created successfully using show.

```
$ terraform show
```
To destroy what we just created, you can run the following command.

```
$ terraform destroy
```

