#!/bin/bash
###################################################################################
#Title           : EFMcript for making node to be a standby of EFM cluster
#                : on resume command
#Author          : Vibhor Kumar (vibhor.aim@gmail.com).
#Date            : Sept 3, 2020
#Version         : 1.0
#Notes           : Install Vim and Emacs to use this script.
#                : configure the .pgpass for EFM user and set
#                : the password correctly
#Bash_version    : GNU bash, version 4.2.46(2)-release (x86_64-redhat-linux-gnu)
###################################################################################

###################################################################################
# initialize all parameters
###################################################################################
readonly EFMBIN="{{ efm_bin_path }}"
readonly EFM="${EFMBIN}/efm"
readonly EFMREWIND="${EFMBIN}/efm_rewind.sh"
readonly EFM_ROOT_FUNCTION="${EFMBIN}/efm_root_functions"
readonly EFM_CLUSTER="{{ efm_cluster_name }}"
readonly PGOWNER="{{ pg_owner }}"

###################################################################################
# Make sure we have stopped the PG service
###################################################################################
/bin/sudo ${EFM_ROOT_FUNCTION} stopdbservice ${EFM_CLUSTER}

###################################################################################
# Get the Primary IP address from the  from the EFM command
###################################################################################

PRIMARY_HOST=$(${EFM} cluster-status ${EFM_CLUSTER} \
                      |grep -e Primary -e Master|head -n1|awk '{print $2}')

/bin/sudo -u ${PGOWNER} ${EFMREWIND} "${PRIMARY_HOST}" 2>&1 \
              | grep -v "could not change directory to"
/bin/sudo ${EFM_ROOT_FUNCTION} stopdbservice ${EFM_CLUSTER} 2>&1 \
              | grep -v "could not change directory to"

/bin/sudo ${EFM_ROOT_FUNCTION} startdbservice ${EFM_CLUSTER} 2>&1 \
              | grep -v "could not change directory to"
${EFM} resume ${EFM_CLUSTER}
/bin/sleep 10
