# CloudNativePG

Further detailed process on how to deploy with helm charts 
[here](https://cloudnative-pg.io/charts/).

### Pre-Requisites
In addition to the pre-requisites for `edb-deployment`,
Deployment of Google Cloud Kubernetes Engine is dependent on following components. Install the following
components before using it.

1. Google Cloud CLI
2. Google Cloud CLI components: [gke-gcloud-auth-plugin](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke), and kubernetes
```shell
$ gcloud components install kubectl
```

2. Packages: openshift, pyyaml, kubernetes, pyhelm

### GCloud GKE Project initialization

Project initialialization will done using the `configure` sub-command:
```shell

edb-deployment gcloud-gke configure gke1 --cnp-type pg --gcloud-region us-west1 --gcloud-credentials ~/accounts.json --gcloud-project-id performance-engineering-268015

$ edb-deploy gcloud-gke configure <PROJECT_NAME> \
  --cnp-type <pg> or <epas> \
  --gcloud-region <region> \
  --gcloud-credentials <google_credentials_file> \
  -gcloud-project-id <Google_Cloud_Project_Id>
```

***Notes:***

## GCloud Kubernetes Configure Help
For more details, please use:
```shell
$ edb-deployment gcloud-gke configure --help
```

## GCloud Kubernetes Setup Requirements

After project configuration, we can proceed to setup requirements:
```shell
$ edb-deployment gcloud-gke setup
```

## GCloud Kubernetes Cluster Provisioning

A Google Cloud Kubernetes Cluster is provisioned with the command below:
```shell
$ edb-deployment gcloud-gke provision <PROJECT_NAME>
```

## GCloud Kubernetes Cluster Deployment

A Google Cloud Kubernetes Cluster with a CloudNativePG Sandbox is deployed with the command below:
```shell
$ edb-deployment gcloud-gke deploy <PROJECT_NAME>
```

## GCloud Kubernetes Cluster Logs

We can view logs with the `logs` sub-command:
```shell
$ edb-deployment gcloud-gke logs <PROJECT_NAME>
```

## GCloud Kubernetes Cluster Destroy

Finally, we can destroy the components with the `destroy` sub-command:
```shell
$ edb-deployment gcloud-gke destroy <PROJECT_NAME>
```

## CloudNativePG Dashboard

To view the CloudNativePG Sandbox Dashboard, open a terminal and execute the command below:
```shell
$ kubectl port-forward svc/cnpg-sandbox-grafana 3000:80
```
Open local browser and navigate towards: http://localhost:3000
Authenticate with the default user and password into grafana
Click on Home -> Browse -> CloudNativePG Dashboard

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
