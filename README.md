# postgres-deployment
EDB Postgres Deployment
Improving the Postgres deployment experience by designing and developing automation that makes Postgres deployments in the cloud, on-premises easy.

Having the Postgres/EDB Postgres Advanced Server deployment scripts available on the git repo allows any user, be it an EDB staff member or any user looking to deploy Postgres/EDB Postgres Advanced Server (EPAS) quickly in a matter of minutes. We have used Terraform for provisioning the infrastructure across multiple providers.

At present, the scripts are available for 2 providers AWS and VMware(vsphere). We will be expanding on the providers in the upcoming versions

AWS

VMware Vsphere

Terraform is used to stand up virtual machines or cloud instances, and then we hand over the reins to Ansible to finish up the configuration of the Postgres database and tools like Failover Manager for high availability and fault tolerance and Postgres Enterprise Manager for monitoring the Postgres cluster.
