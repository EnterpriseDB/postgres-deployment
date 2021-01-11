# Getting Started
The EDB CLI Go is the Command Line Interface for the 'postgres-deployment' scripts. 

# Pre-Requisites:
The EDB CLI Go does not have any dependencies.

# INSTALLATION

* Navigate to the repository as indicated below:
   
  ```git clone https://github.com/EnterpriseDB/edb-deploy.git```
  
  and then select the Release that matches your deployment environment.
 

## USAGE:
* The EDB Deployment CLI has multiple subcommands. Following is an example of viewing the options available through the CLI:

```
Copyright © 2020 EnterpriseDB

Usage:
  edb-deploy [command]

Available Commands:
  create-credentials creating credentials for Deploy
  delete-credentials Delete credentials for Deploy
  help               Help about any command
  update-credentials Update credentials for Deploy
  version            Print the version number of EDB CLI

Flags:
  -h, --help     help for edb-deploy
  -t, --toggle   Help message for toggle

Additional help topics:
  edb-deploy aws                AWS specific commands
  edb-deploy azure              Azure specific commands
  edb-deploy gcloud             Gcloud specific commands

Use "edb-deploy [command] --help" for more information about a command.
```

```
Displays commands for AWS

Usage:
  edb-deploy aws [command]

Available Commands:
  configure   Configure Cluster Configuration for AWS project
  delete      Delete configuration for AWS project
  deploy      Runs Terraform for Google Cloud Project creation and Ansible for Installation of Postgres
  destroy     Runs Terraform for AWS project destruction
  get         Get AWS project details
  install     Runs Ansible to install postgres
  list        Get list of AWS projects
  run         Runs Terraform for AWS project creation

Flags:
  -h, --help   help for aws

Use "edb-deploy aws [command] --help" for more information about a command.
```

## How to Use:
  
* Utilizing the EDB CLI for a Postgres Installation
  * Create a project that details the cloud and other information of the target Cloud Vendor:
```
    ./edb-deploy aws      configure
    ./edb-deploy azure    configure
    ./edb-deploy gcloud   configure
```

  * Create, Install and Configure the Infrastructure in your Cloud Vendor:
```
    ./edb-deploy aws      deploy  -p PROJECT_NAME
    ./edb-deploy azure    deploy  -p PROJECT_NAME 
    ./edb-deploy gcloud   deploy  -p PROJECT_NAME
```

  * Create the Infrastructure in your Cloud Vendor:
```
    ./edb-deploy aws      run  -p PROJECT_NAME
    ./edb-deploy azure    run  -p PROJECT_NAME 
    ./edb-deploy gcloud   run  -p PROJECT_NAME
```

  * Install and configure EDB Postgres in your Cloud Vendor:
```
    ./edb-deploy aws      install  -p PROJECT_NAME
    ./edb-deploy azure    install  -p PROJECT_NAME 
    ./edb-deploy gcloud   install  -p PROJECT_NAME
```

  * Destroy the Infrastructure in your Cloud Vendor:
```
    ./edb-deploy aws      destroy  -p PROJECT_NAME
    ./edb-deploy azure    destroy  -p PROJECT_NAME 
    ./edb-deploy gcloud   destroy  -p PROJECT_NAME
```
  * Display the config file details of a Cloud Project:
```
    ./edb-deploy aws      get  -p PROJECT_NAME
    ./edb-deploy azure    get  -p PROJECT_NAME 
    ./edb-deploy gcloud   get  -p PROJECT_NAME
```
  * Delete a project configuration:
```
    ./edb-deploy aws      delete  -p PROJECT_NAME
    ./edb-deploy azure    delete  -p PROJECT_NAME 
    ./edb-deploy gcloud   delete  -p PROJECT_NAME
```
  * List the available Cloud Projects:
```
    ./edb-deploy aws      list
    ./edb-deploy azure    list
    ./edb-deploy gcloud   list
```


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
