#! /bin/bash

# GCP SDK Installation
sudo rm -r ~/google-cloud-sdk
sudo curl https://sdk.cloud.google.com/ > install.sh
bash install.sh --disable-prompts
PATH=~/google-cloud-sdk/bin:$PATH
gcloud init
