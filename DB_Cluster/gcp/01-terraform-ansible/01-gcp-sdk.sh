#! /bin/bash

# GCP SDK Installation
if cat /etc/*release | grep ^NAME | grep Ubuntu; then
  # Add the Cloud SDK distribution URI as a package source
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

  # Import the Google Cloud public key
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

  # Update the package list and install the Cloud SDK
  sudo apt-get -y update 
  sudo apt-get install -y google-cloud-sdk
else
  sudo rm -r ~/google-cloud-sdk
  sudo curl https://sdk.cloud.google.com/ > install.sh
  bash install.sh --disable-prompts
  PATH=~/google-cloud-sdk/bin:$PATH
fi
gcloud init
