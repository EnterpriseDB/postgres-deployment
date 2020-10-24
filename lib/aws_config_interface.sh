#!/bin/bash

################################################################################
# AWS Interface script for config file
################################################################################
################################################################################
# declare the variables
################################################################################
local PROJECT_NAME=$1
local PROJECT_DIR="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}"
local CONFIG_FILE="${PROJECT_DIR}/${PROJECT_NAME}.cfg"

################################################################################
# create the directories and config file
################################################################################
mkdir -p ${LOGDIR}
mkdir -p ${PROJECT_DIR}

if [[ ! -f ${CONFIG_FILE} ]]
then
   touch ${CONFIG_FILE}
   chmod 600 ${CONFIG_FILE}
else
  source ${CONFIG_FILE}
fi

################################################################################
# Prompt for OS options
################################################################################
echo "Please provide the operating system name from the list"
echo " 1. CentOS7"
echo " 2. Red Hat 7"
echo " 3. CentOS8"
echo " 4. Red Hat 8"
while [[ 0 ]]
do
  if [[  "x${OSNAME}" = "x" ]]
  then
    read -r -e "Please enter your numeric choice: " OPTION
  else
    read -r -e "Please enter your numeric choice [${OSNAME}]: " OPTION
  fi

  OPTION=$(echo ${OPTION}|tr '[:upper:]' '[:lower:]')
  case "${OPTION}" in
    1)
      OSNAME="CentOS7"
      ;;
    2)
      OSNAME="RHEL7"
      ;;
    3)
      OSNAME="CentOS8"
      ;;
    4)
      OSNAME="RHEL8"
      ;;
    "exit") 
      exit 0
      ;;
    *)
      echo "Unknown option. enter a number 1-4 or type 'exit' to quit"
      ;;
  esac
done

################################################################################
# Prompt for REGION options
################################################################################
echo "Please provie the target AWS region from the list"
echo " 1. us-east-1"
echo " 2. us-east-2"
echo " 3. us-west-1"
echo " 4. us-west-2"
while [[ 0 ]]
do
  if [[  "x${REGION}" = "x" ]]
  then
    read -r -e "Please enter your numeric choice: " OPTION
  else
    read -r -e "Please enter your numeric choice [${REGION}]: " OPTION
  fi

  OPTION=$(echo ${OPTION}|tr '[:upper:]' '[:lower:]')

  case "${OPTION}" in
    1)
      REGION="us-east-1"
      ;;
    2)
      REGION="us-east-2"
      ;;
    3)
      REGION="us-west-1"
      ;;
    4)
      REGION="us-west-2"
      ;;
    "exit")
      exit 0
      ;;
    *)
      echo "Unknown option. enter a number 1-4 or type 'exit' to quit"
      ;;
  esac
done

################################################################################
# Prompt for INSTANCE_COUNT options
################################################################################
while [[ 0 ]]
do
  if [[ "x{INSTANCE_COUNT}" = "x" ]]
  then
    read -r -e "Please provie number of AWS EC2 instaces in no. [default 3]: " OPTION
  else
    read -r -e "Please provie number of AWS EC2 instaces in no. [${INSTANCE_COUNT}]: " OPTION
  fi
  OPTION=$(echo ${OPTION}|tr '[:upper:]' '[:lower:]')
  if [[ "${OPTION}" = "exit" ]]
  then
     exit 0
  elif [[ "x${OPTION}" = "x" ]]
  then
     INSTANCE_COUNT=3
  elif ! [[ "${VALUE}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
  then
    echo "Entered value is not a number. enter a number or type 'exit' to quit:"
  else
    INSTANCE_COUNT="${OPTION}"
    break
  fi
done

################################################################################
# Prompt for PEM options
################################################################################
while [[ 0 ]]
do
  echo "Please indicate if you would like a Postgres Enterprise Manager" 
  read -r -e "Yes/No [Yes]: " OPTION
  OPTION=$(echo ${OPTION}|tr '[:upper:]' '[:lower:]')
  if [[ "${OPTION}" = "exit" ]]
  then
      exit 0
  elif [[ "x${OPTION}" = "x" ]] || [[ "x${OPTION}" = "yes" ]]
  then
     INSTANCE_COUNT="$(( INSTANCE_COUNT + 1 ))"
     PEM_INSTANCE_COUNT=1
     break
  elif [[ "${OPTION}" != "no" ]]
  then
    echo "Entered value is not Yes/No. enter the Yes/No or 'exit' to quit."
  fi   
done

################################################################################
# Prompt for ssh public key options
################################################################################
while [[ 0 ]]
do
  echo "Provide the absolute path of public key file"
  read -r -e "[~/.ssh/id_rsa.pub]: " OPTION
  if [[ "x${OPTION}" = "x" ]]
  then
     PUB_FILE_PATH="~/.ssh/id_rsa.pub"
  else
     PUB_FILE_PATH="${OPTION}"
  fi

  if [[ ! -f ${PUB_FILE_PATH} ]]
  then
    echo "${PUB_FILE_PATH} does not exists."
    read -r -e  "Do you want to create a one enter Yes/No or 'exit' to quit" OPTION
    OPTION=$(echo ${VALUE}|tr '[:upper:]' '[:lower:]')
    if [[ "${OPTION}" = "yes" ]]
    then
       ssh-keygen
       break
    elif [[ "${OPTION}" = "exit" ]]
    then 
       exit 0
    fi
  else
    break
  fi
done  
    
################################################################################
# Prompt for ssh private key options
################################################################################
while [[ 0 ]]
do
  echo "Provide the absolute path of private key file"
  read -r -e "[~/.ssh/id_rsa]: " OPTION
  if [[ "x${OPTION}" = "x" ]]
  then
     PRIV_FILE_PATH="~/.ssh/id_rsa"
  else
     PRIV_FILE_PATH="${OPTION}"
  fi

  if [[ ! -f ${PRIV_FILE_PATH} ]]
  then
    echo "${PRIV_FILE_PATH} does not exists."
    read -r -e  "Do you want to create a one enter Yes/No or 'exit' to quit" OPTION
    OPTION=$(echo ${VALUE}|tr '[:upper:]' '[:lower:]')
    if [[ "${OPTION}" = "yes" ]]
    then
       ssh-keygen
       break
    elif [[ "${OPTION}" = "exit" ]]
    then 
       exit 0
    fi
  else
    break
  fi
done
   
################################################################################
# Prompt for PG_TYPE options
################################################################################
echo "Please provide the Postgres engine from the list"
echo " 1. EDB Advanced Server"
echo " 2. PostgreSQL"
while [[ 0 ]]
do
  if [[  "x${OSNAME}" = "x" ]]
  then
    read -r -e "Please enter your numeric choice: " OPTION
  else
    read -r -e "Please enter your numeric choice [${PG_TYPE}]: " OPTION
  fi

  OPTION=$(echo ${OPTION}|tr '[:upper:]' '[:lower:]')
  case "${OPTION}" in
    1)
      PG_TYPE="EPAS"
      ;;
    2)
      PG_TYPE="PG"
      ;;
    "exit")
      exit 0
      ;;
    *)
      echo "Unknown option. enter a number 1-2 or type 'exit' to quit"
      ;;
  esac
done

