#!/bin/bash
set -e
MEIP=eip

id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

aws ec2 associate-address --instance-id "$id" --public-ip "$MEIP" --allow-reassociation --region region-name
