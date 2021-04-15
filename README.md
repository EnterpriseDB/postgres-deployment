# Getting Started

`edb-deployment` tool is an easy way to provision Cloud resources and deploy
PostgreSQL, EDB Postgres Advanced Server and tools (high availability,
backup/recovery, monitoring, connection poolers). `edb-deployment` can also be
used to deploy Postgres architectures on existing infrastructure like physical
servers (baremetal) or local Virtual Machines.

Supported Cloud providers are **AWS**, **Azure** and **Google Cloud**.

`edb-deployment` helps user to deploy Postgres Reference Architectures. List
and details of the Reference Architecture can be find [here](https://github.com/EnterpriseDB/edb-ref-archs/blob/main/edb-reference-architecture-codes/README.md).

`edb-deployment` is an open source tool and is not officially supported by EDB
Support. It is maintained and supported by the GitHub members of this
repository. Please provide feedback by posting issues and providing pull
requests.

Before starting to delve into this repository, it is best to get familiar with
the steps in the deployment process of a specific cloud (AWS, Azure and Google
Cloud).

# Pre-Requisites

`edb-deployment` is dependent on following components. Install the following
components before using it.

1. Python 3
2. `pip3`

Third party pre-requisites:

1. **Latest vendor** Cloud CLI or SDK ( AWS, Azure or Google Cloud )

   Depending on the cloud provider, install the **latest version** for: AWS
   CLI, Azure CLI or Google Cloud SDK on the system.

2. **Terraform** >= 0.13
3. **Ansible** >= 2.9

To help the installation of the third party pre-requisites listed above,
`edb-deployment` provides the `setup` sub-command working for Linux and Darwin
(macOS).
Please refer to section [Pre-Requisites installation](#pre-requisites-installation).

# Installation

## From source code

Installation is done using the `pip3` command. Once the code has been
downloaded, either by cloning the repository or downloading a release, go to
the created folder and run the command `pip3 install`:
```shell
$ cd postgres-deployment
$ sudo pip3 install . --upgrade
```

## From Pypi

```shell
$ sudo pip3 install edb-deployment
```

Make sure the tool is well installed by running the command:
```shell
$ edb-deployment --version
```

## Shell auto-completion

`edb-deployment` supports command line auto-completion with the `tab` key.

Supported shells are `bash` ans `zsh`.

To enable auto-completion in current session, the following command must be
ran:
```shell
$ eval "$(register-python-argcomplete edb-deployment)"
```

To enable auto-completion for all the sessions, the command above must be added
at the end of your `~/.bashrc` file or `~/.zshrc` file, depending on the shell
you use.

## Pre-Requisites installation

To ease installation of the third party pre-requisites tools like `aws`,
`terraform`, `ansible`, etc.. `edb-deployment` provides the `setup`
sub-command.

The following packages are required in order to execute the `setup`
sub-command: `gcc` (Linux only), `python3-devel` (Linux only), `unzip`, `wget`,
`tar`.
These packages should be installed through usual package manager (`dnf`,
`apt`, `brew`, etc..).

Finally, Python `virtualenv` must be installed with `root` privileges:
```shell
$ sudo pip3 install virtualenv
```

Pre-requisites automated installation:
```shell
$ edb-deployment <CLOUD_VENDOR> setup
```

# Usage

Each new deployment will be done under a dedicated name space, this the
`<PROJECT_NAME>`.

`edb-deployment` CLI features are implemented through sub-commands. Each
sub-command can be executed like this:
```shell
$ edb-deployment <CLOUD_VENDOR> <SUB_COMMAND> [<PROJECT_NAME>]
```

## Cloud vendor list

  * `aws`: Amazon Web Services
  * `aws-rds`: Amazon Web Services RDS for PostgreSQL
  * `aws-rds-aurora`: Amazon Aurora
  * `azure`: Microsoft Azure Cloud
  * `gcloud`: Google Cloud

## Sub-commands

  * `configure`: New project initialization and configuration
  * `provision`: Cloud resources provisioning
  * `destroy`: Cloud resources destruction
  * `deploy`: Postgres and tools deployment
  * `show`: Show configuration
  * `display`: Display project inventory
  * `passwords`: Display project passwords
  * `list`: List projects
  * `specs`: Show Cloud Vendor default specifications
  * `logs`: Show project logs
  * `remove`: Remove project

# How to Use

Deployment of new project should follow the work flow below:

  1. [Configure Cloud credentials](#configure-cloud-credentials)
  2. [Project configuration](#project-configuration)
  3. [Cloud resources provisioning](#cloud-resources-provisioning)
  4. [Postgres and tools deployment](#postgres-and-tools-deployment)

## Configure Cloud credentials

This step depends on the target Cloud vendor.

If the Cloud tools have been installed with the help of the `setup`
sub-command, it's recommended to update the value of the `PATH` environment
variable to include tools binary location:
```shell
$ export PATH=$PATH:$HOME/.edb-cloud-tools/bin
```

### AWS credentials configuration

AWS credentials configuration will be done through `aws` tool. For this step,
we need to get your **AWS Access Key ID** and **AWS Secret Access Key**. For
more information about Amazon Access Key management, please go to
[official documentation page](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey).

Run the following command and enter the Access Key ID and Secret Access Key:
```shell
$ aws configure
```

### Azure credentials configuration

Azure Cloud credentials configuration can be achieved using the `az` tool with
the following command:
```shell
$ az login --use-device-code
```

### GCloud credentials configuration

GCloud credentials configuration includes more steps than the other Cloud
vendors. **GCloud project ID** is required.

  1. Login with your email address:
  ```shell
$ gcloud auth login <LOGIN_EMAIL> --no-launch-browser
  ```
  2. Open the link in your browser and copy the given verification code.
  3. Project configuration
  ```shell
$ gcloud config set project <PROJECT_ID>
  ```
  4. To find the IAM account of the service, please enter the following command
     to list service accounts:
  ```shell
$ gcloud iam service-accounts list
  ```
  5. Finally, to create and download a new service account key:
  ```shell
$ gcloud iam service-accounts keys create ~/accounts.json --iam-account=<IAM_ACCOUNT>
  ```

The JSON file `$HOME/accounts.json` must be kept and will be required by
`edb-deployment`.

## Project configuration

Once Cloud vendor credentials have been configured, you can proceed with
project configuration step.

### Cloud vendor specifications

`edb-deployment` brings default configuration values for the Cloud resources
to be provisioned, like **instance type**, **disk size**, **OS image**,
**additional volumes**, etc..

To change these configuration values, you need first to dump the default values
with:
```shell
$ edb-deployment <CLOUD_VENDOR> specs > my_configuration.json
```

When deploying on baremetal servers, IP address and SSH user configuration must
be done through the specifications:

```shell
$ edb-deployment baremetal specs --reference-architecture EDB-RA-1 > baremetal-edb-ra-1.json
```

The `baremetal-edb-ra-1.json` file will contain:
```json
{
  "ssh_user": null,
  "pg_data": null,
  "pg_wal": null,
  "postgres_server_1": {
    "name": "pg1",
    "public_ip": null,
    "private_ip": null
  },
  "pem_server_1": {
    "name": "pem1",
    "public_ip": null,
    "private_ip": null
  },
  "backup_server_1": {
    "name": "backup1",
    "public_ip": null,
    "private_ip": null
  }
}
```

Then, you can edit and update resources configuration stored in the JSON file.

### Project initialization

Project initialialization will done using the `configure` sub-command:
```shell
$ edb-deploy <CLOUD_VENDOR> configure <PROJECT_NAME> \
  -a <REFERENCE_ARCHITECTURE_CODE> \
  -o <OPERATING_SYSTEM> \
  -t <PG_ENGINE_TYPE> \
  -v <PG_VERSION> \
  -u "<EDB_REPO_USERNAME>:<EDB_REPO_PASSWORD>" \
  -r <CLOUD_REGION> \
  -s my_configuration.json
```

Notes:
  * `REFERENCE_ARCHITECTURE_CODE`

    Reference architecture code name. Allowed values are: **EDB-RA-1** for a
    single Postgres node deployment with one backup server and one PEM
    monitoring server, **EDB-RA-2** for a 3 Postgres nodes deployment with
    quorum base synchronous replication and automatic failover, one backup
    server and one PEM monitoring server, **EDB-RA-3** for extending
    **EDB-RA-2** with 3 PgPoolII nodes, and **HammerDB-TPROC-C** for setting up
    a 2-tier configuration for benchmarking with an OLTP workload. Default:
    **EDB-RA-1**

  * `OPERATING_SYSTEM`

    Operating system. Allowed values are: **CentOS7**, **CentOS8**, **RedHat7**
    and **RedHat8**. Default: **CentOS8**

  * `PG_ENGINE_TYPE`

     Postgres engine type. Allowed values are: **PG** for PostgreSQL, **EPAS**
     for EDB Postgres Advanced Server. Default: **PG**

  * `PG_VERSION`

    PostgreSQL or EPAS version. Allowed values are: **11**, **12** and **13**.
    Default: **13**

  * `"EDB_REPO_USERNAME:EDB_REPO_PASSWORD"`

    EDB Packages repository credentials. **Required**.

  * `CLOUD_REGION`

    Cloud vendor region. Default value depends on Cloud vendor.

For more details, please use:
```shell
$ edb-deployment <CLOUD_VENDOR> configure --help
```

## Cloud resources provisioning

After project configuration, we can proceed to Cloud resources provisioning:
```shell
$ edb-deployment <CLOUD_VENDOR> provision <PROJECT_NAME>
```

## Components deployment

Finally, we can deploy the components with the `deploy` sub-command:
```shell
$ edb-deployment <CLOUD_VENDOR> deploy <PROJECT_NAME>
```

## Other features

List of projects:
```shell
$ edb-deployment <CLOUD_VENDOR> list
```

Execute Ansible pre deployment playbook
```shell
$ edb-deployment <CLOUD_VENDOR> deploy --pre-deploy-ansible pre_deploy_playbook.yml <PROJECT_NAME>
```

Execute Ansible post deployment playbook
```shell
$ edb-deployment <CLOUD_VENDOR> deploy --post-deploy-ansible post_deploy_playbook.yml <PROJECT_NAME>
```

Display of projects inventory:
```shell
$ edb-deployment <CLOUD_VENDOR> display <PROJECT_NAME>
```

Display of projects passwords:
```shell
$ edb-deployment <CLOUD_VENDOR> passwords <PROJECT_NAME>
```

Cloud resources destruction:
```shell
$ edb-deployment <CLOUD_VENDOR> destroy <PROJECT_NAME>
```

Project tree deletion:
```shell
$ edb-deployment <CLOUD_VENDOR> remove <PROJECT_NAME>
```

# License

Original work Copyright 2019-2020, EnterpriseDB Corporation

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of EnterpriseDB nor the names of its contributors may be
used to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE.
