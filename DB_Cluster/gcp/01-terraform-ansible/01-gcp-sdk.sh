#! /bin/bash

# GCP SDK Installation
sudo curl https://sdk.cloud.google.com/ > install.sh
sudo rm -r ~/google-cloud-sdk
bash install.sh --disable-prompts
source ~/.bashrc
gcloud init
