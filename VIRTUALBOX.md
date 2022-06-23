# Virtualbox

Further detailed process on how to deploy using `virtualbox` can be found 
[here](https://docs.google.com/document/d/1cuzc6ggXWg0qk2oBZevMqfRoDsz52NVd9EqBpt-en1E/edit?usp=sharing).

### Pre-Requisites
In addition to the pre-requisites for `edb-deployment`,
`virtualbox` is dependent on following components. Install the following
components before using it.

1. Virtualbox
2. Vagrant

### Project initialization

Project initialialization will done using the `configure` sub-command:
```shell
$ edb-deploy virtualbox configure <PROJECT_NAME> \
  -a <REFERENCE_ARCHITECTURE_CODE> \
  -o <OPERATING_SYSTEM> \
  -t <PG_ENGINE_TYPE> \
  -v <PG_VERSION> \
  -u "<EDB_REPO_USERNAME>:<EDB_REPO_PASSWORD>" \
  -m <MEM_SIZE> \
  -c <CPU_COUNT>
```

***Notes:***

  * `REFERENCE_ARCHITECTURE_CODE`

    Reference architecture code name. Allowed values are: **EDB-RA-1** for a
    single Postgres node deployment with one backup server and one PEM
    monitoring server, **EDB-RA-2** for a 3 Postgres nodes deployment with
    quorum base synchronous replication and automatic failover, one backup
	server and one PEM monitoring server, **EDB-RA-3** for extending
	**EDB-RA-2** with 3 PgPoolII nodes. Default: **EDB-RA-1**

  * `OPERATING_SYSTEM`

    Operating system. Allowed values are: **RockyLinux8**
    Default: **RockyLinux8**

  * `PG_ENGINE_TYPE`

     Postgres engine type. Allowed values are: **PG** for PostgreSQL, **EPAS**
     for EDB Postgres Advanced Server. Default: **PG**

  * `PG_VERSION`

    PostgreSQL or EPAS version. Allowed values are: **11**, **12**, **13** and **14**.
    Default: **14**

  * `"EDB_REPO_USERNAME:EDB_REPO_PASSWORD"`

    EDB Packages repository credentials. **Required**.

  * `MEM_SIZE`

    Amount of memory assigned to local machines. **Required**.

    Amount of memory assigned to local machines. **Required**.  
    **EDB-RA-1** deploys 3 servers: pem, barman and primary. 
    You should have at least 9 GB of free space on your machine to deploy.  
    **EDB-RA-2** deploys 5 servers: pem, barman, primary1, primary2 and primary3. 
    You should have at least 15 GB of free space on your machine to deploy.  
    **EDB-RA-3** deploys 8 servers. Pem, barman, primary1, primary2, primary3, pgpool1, pgpool2, and pgpool3. 
    You should have at least 24 GB of free space on your machine to deploy.  
    **Notice**: Even machines with 32 GB of RAM can have difficulty deploying EDB-RA-3 because of the amount of virtual machines that are provisioned and deployed.

  * `CPU_COUNT`

    Number of CPUS assigned to local machines **Required**.

For more details, please use:
```shell
$ edb-deployment virtualbox configure --help
```

## Virtualbox resources provisioning

After project configuration, we can proceed to Virtualbox resources provisioning:
```shell
$ edb-deployment virtualbox provision <PROJECT_NAME>
```

## Components deployment

Finally, we can deploy the components with the `deploy` sub-command:
```shell
$ edb-deployment virtualbox deploy <PROJECT_NAME>
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
