# Getting Started
Postgres Deployment Scripts are an easy way to deploy (PostgreSQL or EDB Postgres Advanced Server) and EDB Tools. It is a contribution by the EDB Team members, which can help people explore Postgres and EDB Tools. Users can interact via the GitHub repository's issues and may add comments in the issues. These deployment scripts are not officially supported by the EDB Support. It is maintained and supported by the GitHub members of this repository.

Before starting to delve into this repository, it is best to get familiar with the steps in the deployment process of a specific cloud (AWS, Azure and Google Cloud).


# Pre-Requisites:
Postgres Deployment Scripts are dependent on following components. Install the following components before using the Postgres Deployment Scripts.

1. **Latest vendor** Cloud CLI or SDK ( AWS, Azure or Google Cloud )

   Depending on the cloud provider, install the **latest version** for: AWS CLI, Azure CLI or Google Cloud SDK on the system.
   
2. Packages: curl and wget
3. Terraform >= 0.13
4. Ansible >= 2.9

# INSTALLATION

* Install the dependent packages are:
  * curl, wget, curl, terraform and ansible
  * To install Terraform: **[Installing Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)**
  * To install Ansible: **[Installing Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)**
  * An example script is provided that is located at: ```./lib/prereqs.sh```

* A CLI or SDK depending on the Cloud vendor to utilize is required: 
  * To install the Amazon Web Services CLI please refer to: **[Installing the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)**
  * To install the Microsoft Azure CLI please refer to: **[Installing the AZURE CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)**
  * To install the Google Cloud SDK please refer to: **[Installing the Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)**

* Download/Clone the repository as indicated below:
  
  For cloning the repository use the following command:
  
  ```git clone https://github.com/EnterpriseDB/postgres-deployment.git```
  
  Download ```postgres-deployment``` GitHub repo by clicking on the green **Code** button followed by clicking the **Download Zip** link

* Extract the zip file to a desired destination
 
* Open the ```Terminal``` command line

* Navigate to the extracted folder location and type: ```cd postgres-deployment``` finishing with pressing the **Enter** button

* Follow the demos/examples to deploy Postgres in a specific cloud.


## USAGE:
* The EDB Deployment CLI is part of the code. Following is an example of viewing the options available through the CLI:

```
edb-deployment [<cloud>-server|<cloud>-postgres] [OPTION]...

EDB deployment script for aws, azure and gcp

Subcommands:
    aws-server      [create|destroy]  PROJECT_NAME
    azure-server    [create|destroy]  PROJECT_NAME
    gcloud-server   [create|destroy]  PROJECT_NAME
    aws-postgres    install           PROJECT_NAME
    azure-postgres  install           PROJECT_NAME
    gcloud-postgres install           PROJECT_NAME
    aws-config      [show|update]     PROJECT_NAME
    azure-config    [show|update]     PROJECT_NAME
    gcloud-config   [show|update]     PROJECT_NAME
    aws-project     [list|switch]     PROJECT_NAME
    azure-project   [list|switch]     PROJECT_NAME
    gcloud-project  [list|switch]     PROJECT_NAME 

Other Options:
    -h, --help Display help and exit
```

## How to Use:
* Create your SSH Key or make it available for its reference
  ![Create SSH Key](./demos/KeyGen.gif)
  
* Utilizing the EDB CLI for a Postgres Installation
  * Create the Infrastructure in your Cloud Vendor:
```
    ./edb-deployment aws-server      create  PROJECT_NAME
    ./edb-deployment azure-server    create  PROJECT_NAME 
    ./edb-deployment gcloud-server   create  PROJECT_NAME
```

  * Install and configure EDB Postgres  in your Cloud Vendor:
```
    ./edb-deployment aws-postgres      install  PROJECT_NAME
    ./edb-deployment azure-postgres    install  PROJECT_NAME 
    ./edb-deployment gcloud-postgres   install  PROJECT_NAME
```

  * Destroy the Infrastructure in your Cloud Vendor:
```
    ./edb-deployment aws-server      destroy  PROJECT_NAME
    ./edb-deployment azure-server    destroy  PROJECT_NAME 
    ./edb-deployment gcloud-server   destroy  PROJECT_NAME
```
  * Display the config file details of Cloud Project:
```
    ./edb-deployment aws-config      show  PROJECT_NAME
    ./edb-deployment azure-config    show  PROJECT_NAME 
    ./edb-deployment gcloud-config   show  PROJECT_NAME
```
  * Edit in vi the config file details of Cloud Project:
```
    ./edb-deployment aws-config      update  PROJECT_NAME
    ./edb-deployment azure-config    update  PROJECT_NAME 
    ./edb-deployment gcloud-config   update  PROJECT_NAME
```
  * List the available Terraform Cloud Projects:
```
    ./edb-deployment aws-project      list  PROJECT_NAME
    ./edb-deployment azure-project    list  PROJECT_NAME 
    ./edb-deployment gcloud-project   list  PROJECT_NAME
```
  * Switch to another available Terraform Cloud Project:
```
    ./edb-deployment aws-project      switch  PROJECT_NAME
    ./edb-deployment azure-project    switch  PROJECT_NAME 
    ./edb-deployment gcloud-project   switch  PROJECT_NAME
```

# Demos/Examples:
* AWS
  * Create Postgres infrastructure in AWS
    ![Create Postgres infrastructure in AWS](./demos/AWS_Create_test.gif)
  * Install Postgres on infrastructure in AWS
    ![Install Postgres against infrastructure in AWS](./demos/AWS_Postgres_Install.gif)
  * Destroy Postgres infrastructure in AWS
    ![Destroy Postgres infrastructure in AWS](./demos/AWS_Destroy_test.gif)
* Azure
  * Create Postgres infrastructure in Azure
    ![Create Postgres infrastructure in Azure](./demos/AZURE_Create_test.gif)
  * Install Postgres on infrastructure in Azure
    ![AZURE Install Postgres on infrastructure in Azure](./demos/AZURE_PEM_Install.gif)
  * Destroy Postgres infrastructure in Azure
    ![Destroy Postgres infrastructure in Azure](./demos/AZURE_Destroy_test.gif)
* Google Cloud
  * Create Postgres infrastructure in Google Cloud
    ![Create Postgres infrastructure in Google Cloud](./demos/GCLOUD_Create_test.gif)
  * Install Postgres on infrastructure in Google Cloud
    ![AZURE Install Postgres on infrastructure in Google Cloud](./demos/GCLOUD_PEM_Install.gif)
  * Destroy Postgres infrastructure in Google Cloud
    ![Destroy Postgres infrastructure in Google Cloud](./demos/GCLOUD_Destroy_test.gif)

# LICENSE
Original work Copyright 2019-2020, EnterpriseDB Corporation

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are 
met:

1. Redistributions of source code must retain the above copyright 
notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright 
notice, this list of conditions and the following disclaimer in the 
documentation and/or other materials provided with the distribution.

3. Neither the name of EnterpriseDB nor the names of its contributors 
may be used to endorse or promote products derived from this software 
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEV
ER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
