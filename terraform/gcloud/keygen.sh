#! /bin/bash
# SSH Key Generation
sudo rm -r ~/.ssh
ssh-keygen
chmod 400 ~/.ssh/id*.*
