#!/bin/bash

CLUSTERNAME=$1
NODETYPE=$2

if [ "$#" -lt 3 ]; then
   echo "You must enter at least 3 command line arguments"
else
   ARGSCOUNTER=0
   COUNTER=0
   CURRENTIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
   for ip in "$@"
   do
      if [ "$ARGSCOUNTER" -gt 1 ]; then
         if [ "$CURRENTIP" == "$ip" ]; then
            NICKNAME="$NODETYPE$COUNTER"
            # Configure shell prompt
            echo "export NICKNAME=$NICKNAME.$CLUSTERNAME.internal" | sudo tee -a /etc/profile.d/prompt.sh
            sudo sed -i "s%\\\\h %$NICKNAME %" /etc/bashrc
            if [ -f /etc/bash.bashrc ]; then
               sudo sed -i "s%\\\\h %$NICKNAME %" /etc/bash.bashrc
            fi
         fi
         ((COUNTER++))         
      fi
      ((ARGSCOUNTER++))
   done
fi
