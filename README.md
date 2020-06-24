# EDB Postgres Deployment
Our goal is to help those who are curious about Postgres experimental deployment experience.  By providing example designs and developing automation templates which can make Postgres deployments easier, on prem or in the cloud.

By making these Postgres/EDB Postgres Advanced Server deployment scripts publicly available on our git repo, our goal is to help you test the waters with Postgres in some of the most common forms we see out there.  With Terraform and Ansible as the framework, provisioning the infrastructure across environments such as AWS and VMware just got easier.

Below, you’ll find a list of the current providers covered; we encourage users to experiment with not only Postgres but these examples themselves.  As we add other providers in the upcoming versions, we will continue to update our content to reflect the changes.[Wiki](https://github.com/EnterpriseDB/postgres-deployment/wiki) page has more details if you need help.

[AWS](https://github.com/EnterpriseDB/postgres-deployment/wiki/AWS)

[VMware Vsphere](https://github.com/EnterpriseDB/postgres-deployment/wiki/VMware---Vsphere)

# Deploy the new instances using Terraform and Configure Postgres Platform
Terraform is used to stand up virtual machines or cloud instances, and then we hand over the reins to Ansible to finish up the configuration of the Postgres database and tools like [Failover Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-failover-manager) for high availability and fault tolerance and [Postgres Enterprise Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-enterprise-manager-pem) for monitoring the Postgres cluster and [EDB Backup and Recovery Tool](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-backup-and-recovery-tool)for backup and recovery purposes.

**NOTE: These scripts are intended as examples for use in explorative or experimental efforts "only". Our scripts are not considered “production-ready”, as most environments are unique and require their own specific implementations.**

**For production efforts, we encourage users to reach out to EnterpriseDB to learn more about our Professional Services capabilities in delivering world-class solutions.**


# Existing Instances available - **Only** Configure Postgres Platform
In case of already running infrastructure be it on AWS or VMWare-Vsphere the user also have an option to use [Ansible scripts](https://github.com/EnterpriseDB/postgres-deployment/wiki/Ansible-Playbooks-for-EDB-tools) made available on the wiki page, to configure the Postgres database and tools like [Failover Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-failover-manager)for high availability and fault tolerance and [Postgres Enterprise Manager](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-enterprise-manager-pem) for monitoring the Postgres cluster and [EDB Backup and Recovery Tool](https://www.enterprisedb.com/enterprise-postgres/edb-postgres-backup-and-recovery-tool)for backup and recovery purposes.

# Support
Postgres Deployment scripts are an easy way to deploy Postgres and EDB tools at no charge. It is a contribution by the EDB team members which can help people explore both Postgres and EDB tools. Users can interact via the git repository comments section so feel free to leave comments there; however, these scripts are not officially supported by the EnterpriseDB team.
EnterpriseDB has the largest base of PostgreSQL experts available. Learn more about Professional Support.

