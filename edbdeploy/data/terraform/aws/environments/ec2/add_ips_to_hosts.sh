#!/bin/bash

CLUSTERNAME=$1
NODETYPE=$2

if [ "$#" -lt 3 ]; then
   echo "You must enter at least 3 command line arguments"
else
   ARGSCOUNTER=0
   COUNTER=0
   for ip in "$@"
   do
      if [ "$ARGSCOUNTER" -gt 1 ]; then
         echo "$ip" "$NODETYPE""$COUNTER"."$CLUSTERNAME".internal | sudo tee -a /etc/hosts
         ((COUNTER++))
      fi
      ((ARGSCOUNTER++))
   done
fi
