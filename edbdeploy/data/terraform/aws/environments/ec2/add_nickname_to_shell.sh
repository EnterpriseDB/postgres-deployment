#!/bin/bash

CLUSTERNAME=$1
NODETYPE=$2

if [ "$#" -lt 3 ]; then
   echo "You must enter at least 23command line arguments"
else
   ARGSCOUNTER=0
   COUNTER=0
   for ip in "$@"
   do
      if [ "$ARGSCOUNTER" -gt 1 ]; then
         echo "$ip" "$NODETYPE""$COUNTER"."$CLUSTERNAME".internal | sudo tee -a /etc/hosts
         # Configure shell prompt
         echo "export NICKNAME=""$NODETYPE""$COUNTER"."$CLUSTERNAME".internal | sudo tee -a /etc/profile.d/prompt.sh
         sudo sed -i "s/\\h \\W/$NODETYPE$COUNTER \\W/g" /etc/bashrc
         if [ -f /etc/bash.bashrc ]; then
            sudo sed -i "s/\\h \\W/$NODETYPE$COUNTER \\W/g" /etc/bash.bashrc
         fi
         # Remove extra characters in shell prompt
         sudo sed -i "s/ WW//" /etc/bashrc
         if [ -f /etc/bash.bashrc ]; then
            sudo sed -i "s/ WW//" /etc/bash.bashrc              
         fi         
         ((COUNTER++))
      fi
      ((ARGSCOUNTER++))
   done
fi
