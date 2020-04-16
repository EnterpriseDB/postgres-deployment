# EDB Postgres Deployment
Improving the Postgres deployment experience by designing and developing automation that makes Postgres deployments in the cloud, on-premises easy.

Having the Postgres/EDB Postgres Advanced Server deployment scripts available on the git repo allows any user, be it an EDB staff member or any user looking to deploy Postgres/[EDB Postgres Advanced Server](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-advanced-server) (EPAS) quickly in a matter of minutes. We have used Terraform for provisioning the infrastructure across multiple providers.

At present, the scripts are available for 2 providers AWS and VMware(vsphere). We will be expanding on the providers in the upcoming versions. [Wiki](https://github.com/EnterpriseDB/postgres-deployment/wiki) page has more details if you need help.

[AWS](https://github.com/EnterpriseDB/postgres-deployment/wiki/AWS)

[VMware Vsphere](https://github.com/EnterpriseDB/postgres-deployment/wiki/VMware---Vsphere)

# Deploy the new instances using Terraform and Configure Postgres Platform
Terraform is used to stand up virtual machines or cloud instances, and then we hand over the reins to Ansible to finish up the configuration of the Postgres database and tools like [Failover Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-failover-manager) for high availability and fault tolerance and [Postgres Enterprise Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-enterprise-manager-pem) for monitoring the Postgres cluster and [EDB Backup and Recovery Tool](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-backup-and-recovery-tool)for backup and recovery purposes.

# Existing Instances available - **Only** Configure Postgres Platform
In case of already running infrastructure be it on AWS or VMWare-Vsphere the user also have an option to use [Ansible scripts](https://github.com/EnterpriseDB/postgres-deployment/wiki/Ansible-Playbooks-for-EDB-tools) made available on the wiki page, to configure the Postgres database and tools like [Failover Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-failover-manager)for high availability and fault tolerance and [Postgres Enterprise Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-enterprise-manager-pem) for monitoring the Postgres cluster and [EDB Backup and Recovery Tool](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-backup-and-recovery-tool)for backup and recovery purposes.

