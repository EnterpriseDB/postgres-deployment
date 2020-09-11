## Getting Started
Before using this module you need to install a few software on your local system or system from where you are going to run the Postgres deployment scripts. 


Download module from EDB git repository on your local system or machine used to deploy the script. The deployment scripts are organized based on the providers currently available. The different folders are named with provider name (eg AWS, VMWARE) at the end. For configuring EFM clusters on previously created Database cluster, you need to go inside folder EFM_Setup_VMWARE.

## Prerequisites
1. Terraform installed 
2. Ansible installed
3. Register for EDB yum repository access. 
4. Existing database cluster set up using EDB postgres deployment scripts.

EDB_EFM_VMWARE module - automates set up of Enterprise Failover Manager cluster. Based on the user input provided in the EFM_Setup_VMWARE/edb_efm_cluster_input.tf file.

If not already done so, please update the file edb_efm_cluster_input.tf in your favorite editor and fill all the mandatory details. Once all the parameters are provided, save the file and proceed with cluster creation steps as follows:-

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

