#! /bin/bash

# GCP SDK Installation

# Install GCP SDK
sudo curl https://sdk.cloud.google.com | bash
gcloud init
exec -l $SHELL | gcloud init
