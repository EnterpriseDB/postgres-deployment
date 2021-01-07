#! /bin/bash
################################################################################
# Title           : config_funcs script to capture the users argument and
#                 : for deployment scripts
# Author          : Doug Ortiz and Co-authored by Vibhor Kumar
# Date            : Sept 7, 2020
# Version         : 1.0
################################################################################

################################################################################
# quit on any error
set -e
# verify any  undefined shell variables
#set -u

################################################################################
# source common lib
################################################################################
DIRECTORY=$(dirname $0)
source ${DIRECTORY}/lib/common_funcs.sh

################################################################################
# function: check the param passed by the user
################################################################################
function check_update_param()
{
    local CONFIG_FILE="$1"
    local MESSAGE="$2"
    local IS_NUMBER="$3"
    local PARAM="$4"

    local READ_INPUT="read -r -e -p"
    local MSG_SUFFIX="PID: $$ [$(date +'%m-%d-%y %H:%M:%S')]: "
    local VALUE
    local CHECK

    CHECK=$(check_variable "${PARAM}" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        ${READ_INPUT} "${MSG_SUFFIX}${MESSAGE}" VALUE
        if [[ -z ${VALUE} ]]
        then
             exit_on_error "Entered value cannot be empty"
        fi
        if [[ "${IS_NUMBER}" = "Yes" ]]
        then
            if ! [[ "${VALUE}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
            then
                exit_on_error "${PARAM} value cannot be string"
            fi
        fi
        if [[ "${PARAM}" = "INSTANCE_COUNT" ]]
        then
            if [[ "${VALUE}" -lt 1 ]]
            then
                exit_on_error "Instance count cannot be less than 1"
            fi
        fi
        if [[ "${PARAM}" = "PEMSERVER" ]]
        then
            VALUE=$(echo ${VALUE}|tr '[:upper:]' '[:lower:]')
            if [[ "${VALUE}" = "yes" ]]
            then
                INSTANCE_COUNT=$(grep INSTANCE_COUNT ${CONFIG_FILE} \
                                    |cut -d"=" -f2)
                if [[ "x${INSTANCE_COUNT}" = "x" ]]
                then
                    INSTANCE_COUNT=1
                else
                    INSTANCE_COUNT=$(( INSTANCE_COUNT + 1 ))
                fi
                validate_variable "INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${INSTANCE_COUNT}"
                PEM_INSTANCE_COUNT=1
                validate_variable "PEM_INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${PEM_INSTANCE_COUNT}"
            fi

            if [[ "${VALUE}" = "no" ]]
            then
                INSTANCE_COUNT=$(grep INSTANCE_COUNT ${CONFIG_FILE} \
                                    |cut -d"=" -f2)
                if [[ "x${INSTANCE_COUNT}" = "x" ]]
                then
                    INSTANCE_COUNT=1
                else
                    INSTANCE_COUNT=$(( INSTANCE_COUNT ))
                fi
                validate_variable "INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${INSTANCE_COUNT}"
                PEM_INSTANCE_COUNT=0
                validate_variable "PEM_INSTANCE_COUNT" \
                                  "${CONFIG_FILE}"  \
                                  "${PEM_INSTANCE_COUNT}"
            fi
        fi
        if [[ "${PARAM}" = "PG_VERSION" ]]
        then
            if [[ "${VALUE}" -lt 10 ]]
            then
                exit_on_error "Instance count cannot be less than 10"
            fi
            if [[ "${VALUE}" -gt 12 ]]
            then
                exit_on_error "Instance count cannot be less than 10"
            fi
        fi
        validate_variable "${PARAM}" "${CONFIG_FILE}" "${VALUE}"
    fi
}

################################################################################
# function: Check if we have configurations or not and prompt accordingly
################################################################################
function aws_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi

    set +u

    # Prompt for OSNAME
    CHECK=$(check_variable "OSNAME" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. CentOS 7' '2. CentOS 8' '3. RHEL 7' '4. RHEL 8')
        declare -a CHOICES=('1' '2' '3' '4')

        RESULT=""
        custom_options_prompt "Which Operating System would you like to Install?" \
           "Please enter your choice:" \
           OPTIONS \
           CHOICES \
           RESULT
        case "${RESULT}" in
          1)
            OSNAME="CentOS7"
            ;;
          2)
            OSNAME="CentOS8"
            ;;
          3)
            OSNAME="RHEL7"
            ;;
          4)
            OSNAME="RHEL8"
            ;;
      esac
    fi
    export OSNAME
    validate_variable "OSNAME" "${CONFIG_FILE}" "${OSNAME}"

    # Prompt for REGION
    CHECK=$(check_variable "REGION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. us-east-1' '2. us-east-2' '3. us-west-1' '4. us-west-2')
        declare -a CHOICES=('1' '2' '3' '4')

        RESULT=""
        custom_options_prompt "Which Region would you like to use?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
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
        esac
    fi
    export REGION
    validate_variable "REGION" "${CONFIG_FILE}" "${REGION}"

    CHECK=$(check_variable "INSTANCE_COUNT" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Single Installation' '2. Multi-Node Installation')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "How many AWS EC2 Instances would you like to create?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "0"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "No"
            export INSTANCE_COUNT
            export PEM_INSTANCE_COUNT
            export PEMSERVER
            ;;
          2)
            # Ask about how many instances for multi-node cluster
            RESULT=""
            validate_string_not_empty \
              "Please enter how many AWS EC2 Instances you would like for the Multi-Node Cluster? " \
              "" \
              RESULT
            RESULT=$(( RESULT + 1 ))
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "${RESULT}"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "Yes"
            export INSTANCE_COUNT
            export PEM_INSTANCE_COUNT
            export PEMSERVER
            ;;
        esac
    fi

    # Public Key File
    CHECK=$(check_variable "PUB_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=("1. Default = [${HOME}/.ssh/id_rsa.pub]" '2. Custom')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which public key file will you choose?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            validate_variable "PUB_FILE_PATH" "${CONFIG_FILE}" "${HOME}/.ssh/id_rsa.pub"
            export PUB_FILE_PATH
            ;;
          2)
            # Ask about how many instances for multi-node cluster
            RESULT=""
            validate_string_not_empty "What will the absolute path of the public key file be?" \
              "[${HOME}/.ssh/id_rsa.pub]: " \
              RESULT
            PUB_FILE_PATH="${RESULT}"
            validate_variable "PUB_FILE_PATH" "${CONFIG_FILE}" "${PUB_FILE_PATH}"
            export PUB_FILE_PATH
            ;;
        esac

        #RESULT=""
        #validate_string_not_empty "What will the absolute path of the public key file be?" \
        #  "[${HOME}/.ssh/id_rsa.pub] (Enter will utilize the listed value as default): " \
        #  RESULT
        #PUB_FILE_PATH="${RESULT}"
    fi
    #validate_variable "PUB_FILE_PATH" "${CONFIG_FILE}" "${PUB_FILE_PATH}"
    #export PUB_FILE_PATH

    # Private Key File
    CHECK=$(check_variable "PRIV_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=("1. Default = [${HOME}/.ssh/id_rsa]" '2. Custom')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which private key file will you choose?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            validate_variable "PRIV_FILE_PATH" "${CONFIG_FILE}" "${HOME}/.ssh/id_rsa"
            export PRIV_FILE_PATH
            ;;
          2)
            # Ask about how many instances for multi-node cluster
            RESULT=""
            validate_string_not_empty "What will the absolute path of the private key file be?" \
              "[${HOME}/.ssh/id_rsa]: " \
              RESULT
            PRIV_FILE_PATH="${RESULT}"
            validate_variable "PRIV_FILE_PATH" "${CONFIG_FILE}" "${PRIV_FILE_PATH}"
            export PRIV_FILE_PATH
            ;;
        esac

        #RESULT=""
        #validate_string_not_empty "What will the absolute path of the private key file be?" \
        #  "[${HOME}/.ssh/id_rsa]: (Enter will utilize the listed value as default)" \
        #  RESULT
        #PRIV_FILE_PATH="${RESULT}"
    fi
    #validate_variable "PRIV_FILE_PATH" "${CONFIG_FILE}" "${PRIV_FILE_PATH}"
    #export PRIV_FILE_PATH

    # Prompt for Database Engine
    CHECK=$(check_variable "PG_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Postgres' '2. EDB Postgres Advanced Server')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which Database Engine would you like to install?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            PG_TYPE="PG"
            ;;
          2)
            PG_TYPE="EPAS"
            ;;
        esac
    fi
    validate_variable "PG_TYPE" "${CONFIG_FILE}" "${PG_TYPE}"
    export PG_TYPE

    # Prompt for Database Engine Version
    CHECK=$(check_variable "PG_VERSION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. 10' '2. 11' '3. 12')
        declare -a CHOICES=('1' '2' '3')

        RESULT=""
        custom_options_prompt "Which Database Version do you wish to install?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            PG_VERSION="10"
            break
            ;;
          2)
            PG_VERSION="11"
            ;;
          3)
            PG_VERSION="12"
            ;;
        esac
    fi
    validate_variable "PG_VERSION" "${CONFIG_FILE}" "${PG_VERSION}"
    export PG_VERSION

    # Prompt for Standby Replication Type
    CHECK=$(check_variable "STANDBY_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. synchronous' '2. asynchronous')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which type of replication would you like for standby nodes?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            STANDBY_TYPE="synchronous"
            ;;
          2)
            STANDBY_TYPE="asynchronous"
            ;;
        esac
    fi
    export STANDBY_TYPE
    validate_variable "STANDBY_TYPE" "${CONFIG_FILE}" "${STANDBY_TYPE}"

    # AMI ID
    CHECK=$(check_variable "AMI_ID" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        custom_yesno_prompt "Do you want to utilize an AMI ID for the Instances?" \
          "Enter: (Y)es/(N)o" \
          RESULT
        if [[ "${RESULT}" = "Yes" ]]
        then
            RESULT=""
            validate_string_not_empty "Please enter the AMI ID: " "" RESULT
            AMI_ID="${RESULT}"
        else
            AMI_ID="${RESULT}"
        fi
    fi
    validate_variable "AMI_ID" "${CONFIG_FILE}" "${AMI_ID}"
    export AMI_ID

    # Instance Volumes
    CHECK=$(check_variable "INSTANCE_VOLUME_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then

        # Comment below for prompting details about Additional Volumes
        RESULT="No"
        # Un-Comment to prompt for Additional Volumes in CLI
        # Additional Volumes
        #RESULT=""
        #custom_yesno_prompt "Do you want to configure the instances main volume?" \
        #  "Enter: (Y)es/(N)o" \
        #  RESULT
        if [[ "${RESULT}" = "Yes" ]]
        then
            # Volume Type
            declare -a OPTIONS=('1. gp2' '2. io1' '3. io2')
            declare -a CHOICES=('1' '2' '3')

            RESULT=""
            custom_options_prompt "Which type of disk type for the instances main volume would you like?" \
               "Please enter your choice:" \
               OPTIONS \
               CHOICES \
               RESULT
            case "${RESULT}" in
              1)
                VIOPSTYPE="gp2"
                ;;
              2)
                VIOPSTYPE="io1"
                ;;
              3)
                VIOPSTYPE="io2"
                ;;
            esac
            validate_variable "INSTANCE_VOLUME_TYPE" "${CONFIG_FILE}" "${VIOPSTYPE}"
            export INSTANCE_VOLUME_TYPE

            # Volume Size
            CHECK=$(check_variable "INSTANCE_VOLUME_SIZE" "${CONFIG_FILE}")
            if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
            then
                RESULT=""
                validate_string_not_empty "Please enter the size in GB for main volume: " "" RESULT
                VS="${RESULT}"
                validate_variable "INSTANCE_VOLUME_SIZE" "${CONFIG_FILE}" "${VS}"
                export INSTANCE_VOLUME_SIZE
            fi

            # Volume IOPS
            CHECK=$(check_variable "INSTANCE_VOLUME_IOPS" "${CONFIG_FILE}")
            if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
            then
                VIOPS=250
                if [[ "${VIOPSTYPE}" = "io1" ]] || [[ "${VIOPSTYPE}" = "io2" ]]
                then
                    declare -a OPTIONS=('1. 250' '2. 350' '3. 3000' '4. Custom')
                    declare -a CHOICES=('1' '2' '3' '4')

                    RESULT=""

                    custom_options_prompt "Which provisioned size for iops for the instances main volume would you like?" \
                      "Please enter your choice:" \
                      OPTIONS \
                      CHOICES \
                      RESULT
                    case "${RESULT}" in
                      1)
                        VIOPS=250
                        ;;
                      2)
                        VIOPS=350
                        ;;
                      3)
                        VIOPS=3000
                        ;;
                      4)
                        RESULT=""
                        validate_string_not_empty "Please enter the custom IOPS value: " "" RESULT
                        VIOPS="${RESULT}"
                        ;;
                    esac
                fi
                validate_variable "INSTANCE_VOLUME_IOPS" "${CONFIG_FILE}" "${VIOPS}"
                export INSTANCE_VOLUME_IOPS
            fi
        else
            validate_variable "INSTANCE_VOLUME_TYPE" "${CONFIG_FILE}" "gp2"
            validate_variable "INSTANCE_VOLUME_SIZE" "${CONFIG_FILE}" "100"
            validate_variable "INSTANCE_VOLUME_IOPS" "${CONFIG_FILE}" "250"
            export INSTANCE_VOLUME_TYPE
            export INSTANCE_VOLUME_SIZE
            export INSTANCE_VOLUME_IOPS
        fi
    fi

    # Additional Volumes
    CHECK=$(check_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then

        # Comment below for prompting details about Additional Volumes
        RESULT="No"
        # Un-Comment to prompt for Additional Volumes in CLI
        # Additional Volumes
        #RESULT=""
        #custom_yesno_prompt "Do you want separate volume for PGDATA, PGWAL and Tablespaces?" \
        #  "Enter: (Y)es/(N)o" \
        #  RESULT
        if [[ "${RESULT}" = "Yes" ]]
        then
            declare -a OPTIONS=('1. gp2' '2. io1' '3. io2')
            declare -a CHOICES=('1' '2' '3')

            RESULT=""
            custom_options_prompt "Which type of disk volume would you like?" \
              "Please enter your choice:" \
              OPTIONS \
              CHOICES \
              RESULT
            case "${RESULT}" in
              1)
                AIOPSTYPE="gp2"
                ;;
              2)
                AIOPSTYPE="io1"
                ;;
              3)
                AIOPSTYPE="io2"
                ;;
            esac

            AIOPS=250
            if [[ "${VIOPSTYPE}" = "io1" ]] || [[ "${VIOPSTYPE}" = "io2" ]]
            then
                declare -a OPTIONS=('1. 250' '2. 350' '3. 3000' '4. Custom')
                declare -a CHOICES=('1' '2' '3' '4')

                RESULT=""
                custom_options_prompt "Which provisioned size for iops would you like?" \
                  "Please enter your choice:" \
                  OPTIONS \
                  CHOICES \
                  RESULT
                case "${RESULT}" in
                  1)
                    AIOPS=250
                    ;;
                  2)
                    AIOPS=350
                    ;;
                  3)
                    AIOPS=3000
                    ;;
                  4)
                    RESULT=""
                   validate_string_not_empty "Please enter the custom IOPS value: " "" RESULT
                   AIOPS="${RESULT}"
                   ;;
                esac
            fi
            RESULT=""
            validate_string_not_empty "Please enter the size in GB for volumes: " "" RESULT
            AVS="${RESULT}"
            RESULT=""
            custom_yesno_prompt "Do you wish to encrypt the volumes ?" \
              "Enter: (Y)es/(N)o" \
              RESULT
            if [[ "${RESULT}" = "Yes" ]]
            then
                AVS_ENCRYPTION="true"
            else
                AVS_ENCRYPTION="false"
            fi
            validate_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}" "5"
            validate_variable "ADDITIONAL_VOLUMES_TYPE" "${CONFIG_FILE}" "${AIOPSTYPE}"
            validate_variable "ADDITIONAL_VOLUMES_SIZE" "${CONFIG_FILE}" "${AVS}"
            validate_variable "ADDITIONAL_VOLUMES_IOPS" "${CONFIG_FILE}" "${AIOPS}"
            validate_variable "ADDITIONAL_VOLUMES_ENCRYPTION" "${CONFIG_FILE}" "${AVS_ENCRYPTION}"
            export ADDITIONAL_VOLUMES_COUNT
            export ADDITIONAL_VOLUMES_TYPE
            export ADDITIONAL_VOLUMES_SIZE
            export ADDITIONAL_VOLUMES_IOPS
            export ADDITIONAL_VOLUMES_ENCRYPTION
        else
            validate_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}" "0"
            validate_variable "ADDITIONAL_VOLUMES_TYPE" "${CONFIG_FILE}" "No"
            validate_variable "ADDITIONAL_VOLUMES_SIZE" "${CONFIG_FILE}" "0"
            validate_variable "ADDITIONAL_VOLUMES_IOPS" "${CONFIG_FILE}" "0"
            validate_variable "ADDITIONAL_VOLUMES_ENCRYPTION" "${CONFIG_FILE}" "false"
            export ADDITIONAL_VOLUMES_COUNT
            export ADDITIONAL_VOLUMES_TYPE
            export ADDITIONAL_VOLUMES_SIZE
            export ADDITIONAL_VOLUMES_IOPS
            export ADDITIONAL_VOLUMES_ENCRYPTION
        fi
    fi

    # EDB YUM UserName
    CHECK=$(check_variable "YUM_USERNAME" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "Please provide EDB Yum Username: " "" RESULT
        YUM_USERNAME="${RESULT}"
    fi
    validate_variable "YUM_USERNAME" "${CONFIG_FILE}" "${YUM_USERNAME}"
    export YUM_USERNAME

    # EDB YUM Password
    CHECK=$(check_variable "YUM_PASSWORD" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_password_not_empty "Please provide EDB Yum Password: " "" RESULT
        YUM_PASSWORD="${RESULT}"
    fi
    validate_variable "YUM_PASSWORD" "${CONFIG_FILE}" "${YUM_PASSWORD}"
    export YUM_PASSWORD

    echo " "
    set -u

    process_log "set all parameters"
    source ${CONFIG_FILE}
}

function azure_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi

    set +u

    # Prompt for Publisher
    CHECK=$(check_variable "PUBLISHER" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. OpenLogic' '2. Redhat')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which Publisher would you like to choose?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            PUBLISHER="OpenLogic"
            ;;
          2)
            PUBLISHER="Redhat"
            ;;
        esac
    fi
    validate_variable "PUBLISHER" "${CONFIG_FILE}" "${PUBLISHER}"
    export PUBLISHER

    # Prompt for Offer
    CHECK=$(check_variable "OFFER" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Centos 7.7' '2. Centos 8.1' '3. RHEL 7.8' '4. RHEL 8.2')
        declare -a CHOICES=('1' '2' '3' '4')

        RESULT=""
        custom_options_prompt "Which Operating System would you like to use?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            OFFER="Centos"
            SKU="7.7"
            ;;
          2)
            OFFER="Centos"
            SKU="8_1"
            ;;
          3)
            OFFER="RHEL"
            SKU="7.8"
            ;;
          4)
            OFFER="RHEL"
            SKU="8.2"
            ;;
        esac
    fi
    validate_variable "OFFER" "${CONFIG_FILE}" "${OFFER}"
    validate_variable "SKU" "${CONFIG_FILE}" "${SKU}"
    export OFFER
    export SKU

    # Prompt for LOCATION
    CHECK=$(check_variable "LOCATION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. centralus' '2. eastus' '3. eastus2' '4. westus' \
          '5. westcentralus' '6. westus2' '7. northcentralus' '8. southcentralus')
        declare -a CHOICES=('1' '2' '3' '4' '5' '6' '7' '8')

        RESULT=""
        custom_options_prompt "Which Azure Location will you deploy towards?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            LOCATION="centralus"
            ;;
          2)
            LOCATION="eastus"
            ;;
          3)
            LOCATION="eastus2"
            ;;
          4)
            LOCATION="westus"
            ;;
          5)
            LOCATION="westcentralus"
            ;;
          6)
            LOCATION="westus2"
            ;;
          7)
            LOCATION="northcentralus"
            ;;
          8)
            LOCATION="southcentralus"
            ;;
        esac
    fi
    export LOCATION
    validate_variable "LOCATION" "${CONFIG_FILE}" "${LOCATION}"

    CHECK=$(check_variable "INSTANCE_COUNT" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Single Installation' '2. Multi-Node Installation')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "How many Virtual Machines would you like to create?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "0"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "No"
            export INSTANCE_COUNT
            export PEM_INSTANCE_COUNT
            export PEMSERVER
            ;;
          2)
            # Ask about how many instances for multi-node cluster
            RESULT=""
            validate_string_not_empty \
              "Please enter how many Virtual Machines you would like for the Multi-Node Cluster? " \
              "" \
              RESULT
            RESULT=$(( RESULT + 1 ))
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "${RESULT}"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "Yes"
            export INSTANCE_COUNT
            export PEM_INSTANCE_COUNT
            export PEMSERVER
            ;;
        esac
    fi

    # Public Key File
    CHECK=$(check_variable "PUB_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "What will the absolute path of the public key file be?" \
          "[${HOME}/.ssh/id_rsa.pub]: " \
          RESULT
        PUB_FILE_PATH="${RESULT}"
    fi
    validate_variable "PUB_FILE_PATH" "${CONFIG_FILE}" "${PUB_FILE_PATH}"
    export PUB_FILE_PATH

    # Private Key File
    CHECK=$(check_variable "PRIV_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "What will the absolute path of the private key file be?" \
          "[${HOME}/.ssh/id_rsa]: " \
          RESULT
        PRIV_FILE_PATH="${RESULT}"
    fi
    validate_variable "PRIV_FILE_PATH" "${CONFIG_FILE}" "${PRIV_FILE_PATH}"
    export PRIV_FILE_PATH

    # Prompt for Database Engine
    CHECK=$(check_variable "PG_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Postgres' '2. EDB Postgres Advanced Server')
        declare -a CHOICES=('1' '2')

        RESULT=""
        echo "${options[@]}"
        custom_options_prompt "Which Database Engine would you like to install?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            PG_TYPE="PG"
            ;;
          2)
            PG_TYPE="EPAS"
            ;;
        esac
    fi
    validate_variable "PG_TYPE" "${CONFIG_FILE}" "${PG_TYPE}"
    export PG_TYPE

    # Prompt for Database Engine Version
    CHECK=$(check_variable "PG_VERSION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. 10' '2. 11' '3. 12')
        declare -a CHOICES=('1' '2' '3')

        RESULT=""
        custom_options_prompt "Which Database Version do you wish to install?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            PG_VERSION="10"
            break
            ;;
          2)
            PG_VERSION="11"
            ;;
          3)
            PG_VERSION="12"
            ;;
        esac
    fi
    validate_variable "PG_VERSION" "${CONFIG_FILE}" "${PG_VERSION}"
    export PG_VERSION

    # Prompt for Standby Replication Type
    CHECK=$(check_variable "STANDBY_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. synchronous' '2. asynchronous')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which type of replication would you like for standby nodes?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            STANDBY_TYPE="synchronous"
            ;;
          2)
            STANDBY_TYPE="asynchronous"
            ;;
        esac
    fi
    export STANDBY_TYPE
    validate_variable "STANDBY_TYPE" "${CONFIG_FILE}" "${STANDBY_TYPE}"

    # Additional Volumes
    CHECK=$(check_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then

        # Comment below for prompting details about Additional Volumes
        RESULT="No"
        # Un-Comment to prompt for Additional Volumes in CLI
        # Additional Volumes
        #RESULT=""
        #custom_yesno_prompt "Do you want separate volume for PGDATA, PGWAL and Tablespaces?" \
        #  "Enter: (Y)es/(N)o" \
        #  RESULT
        if [[ "${RESULT}" = "Yes" ]]
        then
            declare -a OPTIONS=('1. Standard' '2. SSD')
            declare -a CHOICES=('1' '2')

            RESULT=""
            custom_options_prompt "Which type of disk volume would you like?" \
              "Please enter your choice:" \
              OPTIONS \
              CHOICES \
              RESULT
            case "${RESULT}" in
              1)
                ADISKTYPE="Standard_LRS"
                ;;
              2)
                ADISKTYPE="StandardSSD_LRS"
                ;;
            esac

            RESULT=""
            validate_string_not_empty "Please enter the size in GB for volumes: " "" RESULT
            AVS="${RESULT}"
            validate_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}" "5"
            validate_variable "ADDITIONAL_VOLUMES_DISKTYPE" "${CONFIG_FILE}" "${ADISKTYPE}"
            validate_variable "ADDITIONAL_VOLUMES_SIZE" "${CONFIG_FILE}" "${AVS}"
            export ADDITIONAL_VOLUMES_COUNT
            export ADDITIONAL_VOLUMES_DISKTYPE
            export ADDITIONAL_VOLUMES_SIZE
        else
            validate_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}" "0"
            validate_variable "ADDITIONAL_VOLUMES_DISKTYPE" "${CONFIG_FILE}" "Standard_LRS"
            validate_variable "ADDITIONAL_VOLUMES_SIZE" "${CONFIG_FILE}" "0"
            export ADDITIONAL_VOLUMES_COUNT
            export ADDITIONAL_VOLUMES_DISKTYPE
            export ADDITIONAL_VOLUMES_SIZE
        fi
    fi

    # EDB YUM UserName
    CHECK=$(check_variable "YUM_USERNAME" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "Please provide EDB Yum Username: " "" RESULT
        YUM_USERNAME="${RESULT}"
    fi
    validate_variable "YUM_USERNAME" "${CONFIG_FILE}" "${YUM_USERNAME}"
    export YUM_USERNAME

    # EDB YUM Password
    CHECK=$(check_variable "YUM_PASSWORD" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_password_not_empty "Please provide EDB Yum Password: " "" RESULT
        YUM_PASSWORD="${RESULT}"
    fi
    validate_variable "YUM_PASSWORD" "${CONFIG_FILE}" "${YUM_PASSWORD}"
    export YUM_PASSWORD

    set -u

    process_log "set all parameters"
    source ${CONFIG_FILE}
}

function gcloud_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}/${PROJECT_NAME}.cfg"
    local READ_INPUT="read -r -e -p"

    local MESSAGE

    mkdir -p ${LOGDIR}
    mkdir -p ${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}

    if [[ ! -f ${CONFIG_FILE} ]]
    then
       touch ${CONFIG_FILE}
       chmod 600 ${CONFIG_FILE}
    else
        source ${CONFIG_FILE}
    fi

    set +u

    # Prompt for OSNAME
    CHECK=$(check_variable "OSNAME" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. centos-7' '2. centos-8' '3. rhel-7' '4. rhel-8')
        declare -a CHOICES=('1' '2' '3' '4')

        RESULT=""
        custom_options_prompt "Which Operating System and Version would you like to use?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            OSNAME="centos-7"
            ;;
          2)
            OSNAME="centos-8"
            ;;
          3)
            OSNAME="rhel-7"
            ;;
          4)
            OSNAME="rhel-8"
            ;;
        esac
    fi
    export OSNAME
    validate_variable "OSNAME" "${CONFIG_FILE}" "${OSNAME}"

    # Prompt for Google Project ID
    CHECK=$(check_variable "PROJECT_ID" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "What is your Google Project ID?" \
          "" \
          RESULT
        PROJECT_ID="${RESULT}"
    fi
    validate_variable "PROJECT_ID" "${CONFIG_FILE}" "${PROJECT_ID}"
    export PROJECT_ID

    # Prompt for SUBNETWORK_REGION
    CHECK=$(check_variable "SUBNETWORK_REGION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. us-central1' '2. us-east1' '3. us-east4' '4. us-west1' \
          '5. us-west2' '6. us-west3' '7. us-west4')
        declare -a CHOICES=('1' '2' '3' '4' '5' '6' '7')

        RESULT=""
        custom_options_prompt "Which Azure Location will you deploy towards?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            SUBNETWORK_REGION="us-central1"
            ;;
          2)
            SUBNETWORK_REGION="us-east1"
            ;;
          3)
            SUBNETWORK_REGION="us-east4"
            ;;
          4)
            SUBNETWORK_REGION="us-west1"
            ;;
          5)
            SUBNETWORK_REGION="us-west2"
            ;;
          6)
            SUBNETWORK_REGION="us-west3"
            ;;
          7)
            SUBNETWORK_REGION="us-west4"
            ;;
        esac
    fi
    export SUBNETWORK_REGION
    validate_variable "SUBNETWORK_REGION" "${CONFIG_FILE}" "${SUBNETWORK_REGION}"

    CHECK=$(check_variable "INSTANCE_COUNT" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Single Installation' '2. Multi-Node Installation')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "How many Virtual Machines would you like to create?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "0"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "No"
            export INSTANCE_COUNT
            export PEM_INSTANCE_COUNT
            export PEMSERVER
            ;;
          2)
            # Ask about how many instances for multi-node cluster
            RESULT=""
            validate_string_not_empty \
              "Please enter how many Virtual Machines you would like for the Multi-Node Cluster? " \
              "" \
              RESULT
            RESULT=$(( RESULT + 1 ))
            validate_variable "INSTANCE_COUNT" "${CONFIG_FILE}" "${RESULT}"
            validate_variable "PEM_INSTANCE_COUNT" "${CONFIG_FILE}" "1"
            validate_variable "PEMSERVER" "${CONFIG_FILE}" "Yes"
            export INSTANCE_COUNT
            export PEM_INSTANCE_COUNT
            export PEMSERVER
            ;;
        esac
    fi

    # Credentials File
    CHECK=$(check_variable "CREDENTIALS_FILE_LOCATION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "Where is the location of your Credentials file?" \
          "[${HOME}/accounts.json]: " \
          RESULT
        CREDENTIALS_FILE_LOCATION="${RESULT}"
    fi
    validate_variable "CREDENTIALS_FILE_LOCATION" "${CONFIG_FILE}" "${CREDENTIALS_FILE_LOCATION}"
    export CREDENTIALS_FILE_LOCATION

    # Public Key File
    CHECK=$(check_variable "PUB_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "What will the absolute path of the public key file be?" \
          "[${HOME}/.ssh/id_rsa.pub]: " \
          RESULT
        PUB_FILE_PATH="${RESULT}"
    fi
    validate_variable "PUB_FILE_PATH" "${CONFIG_FILE}" "${PUB_FILE_PATH}"
    export PUB_FILE_PATH

    # Private Key File
    CHECK=$(check_variable "PRIV_FILE_PATH" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "What will the absolute path of the private key file be?" \
          "[${HOME}/.ssh/id_rsa]: " \
          RESULT
        PRIV_FILE_PATH="${RESULT}"
    fi
    validate_variable "PRIV_FILE_PATH" "${CONFIG_FILE}" "${PRIV_FILE_PATH}"
    export PRIV_FILE_PATH

    # Prompt for Database Engine
    CHECK=$(check_variable "PG_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. Postgres' '2. EDB Postgres Advanced Server')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which Database Engine would you like to install?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            PG_TYPE="PG"
            ;;
          2)
            PG_TYPE="EPAS"
            ;;
        esac
    fi
    validate_variable "PG_TYPE" "${CONFIG_FILE}" "${PG_TYPE}"
    export PG_TYPE

    # Prompt for Database Engine Version
    CHECK=$(check_variable "PG_VERSION" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. 10' '2. 11' '3. 12')
        declare -a CHOICES=('1' '2' '3')

        RESULT=""
        custom_options_prompt "Which Database Version do you wish to install?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            PG_VERSION="10"
            break
            ;;
          2)
            PG_VERSION="11"
            ;;
          3)
            PG_VERSION="12"
            ;;
        esac
    fi
    validate_variable "PG_VERSION" "${CONFIG_FILE}" "${PG_VERSION}"
    export PG_VERSION

    # Prompt for Standby Replication Type
    CHECK=$(check_variable "STANDBY_TYPE" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        declare -a OPTIONS=('1. synchronous' '2. asynchronous')
        declare -a CHOICES=('1' '2')

        RESULT=""
        custom_options_prompt "Which type of replication would you like for standby nodes?" \
          "Please enter your choice:" \
          OPTIONS \
          CHOICES \
          RESULT
        case "${RESULT}" in
          1)
            STANDBY_TYPE="synchronous"
            ;;
          2)
            STANDBY_TYPE="asynchronous"
            ;;
        esac
    fi
    export STANDBY_TYPE
    validate_variable "STANDBY_TYPE" "${CONFIG_FILE}" "${STANDBY_TYPE}"

    CHECK=$(check_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        # Comment below for prompting details about Additional Volumes
        RESULT="No"
        # Un-Comment to prompt for Additional Volumes in CLI
        # Additional Volumes
        # custom_yesno_prompt "Do you want separate volume for PGDATA, PGWAL and Tablespaces?" \
        #   "Enter: (Y)es/(N)o" \
        #   RESULT
        if [[ "${RESULT}" = "Yes" ]]
        then
            declare -a OPTIONS=('1. Standard' '2. Balanced' '3. SSD')
            declare -a CHOICES=('1' '2' '3')

            RESULT=""
            custom_options_prompt "Which type of disk volume would you like?" \
              "Please enter your choice:" \
              OPTIONS \
              CHOICES \
              RESULT
            case "${RESULT}" in
              1)
                ADISKTYPE="pd-standard"
                ;;
              2)
                ADISKTYPE="pd-balanced"
                ;;
              3)
                ADISKTYPE="pd-ssd"
                ;;
            esac

            RESULT=""
            validate_string_not_empty "Please enter the size in GB for volumes: " "" RESULT
            AVS="${RESULT}"
            validate_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}" "5"
            validate_variable "ADDITIONAL_VOLUMES_DISKTYPE" "${CONFIG_FILE}" "${ADISKTYPE}"
            validate_variable "ADDITIONAL_VOLUMES_SIZE" "${CONFIG_FILE}" "${AVS}"
            export ADDITIONAL_VOLUMES_COUNT
            export ADDITIONAL_VOLUMES_DISKTYPE
            export ADDITIONAL_VOLUMES_SIZE
        else
            validate_variable "ADDITIONAL_VOLUMES_COUNT" "${CONFIG_FILE}" "0"
            validate_variable "ADDITIONAL_VOLUMES_DISKTYPE" "${CONFIG_FILE}" "pd-standard"
            validate_variable "ADDITIONAL_VOLUMES_SIZE" "${CONFIG_FILE}" "0"
            export ADDITIONAL_VOLUMES_COUNT
            export ADDITIONAL_VOLUMES_DISKTYPE
            export ADDITIONAL_VOLUMES_SIZE
        fi
    fi

    CHECK=$(check_variable "DISK_ENCRYPTION_KEY" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        # Comment below for prompting details about Additional Volumes
        RESULT="No"
        # Un-Comment to prompt for Disk Encryption Key
        # Additional Volumes
        #custom_yesno_prompt "Do you want to provide an Encryption Key for the Disks?" \
        #  "Enter: (Y)es/(N)o" \
        #  RESULT
        if [[ "${RESULT}" = "Yes" ]]
        then
            RESULT=""
            validate_string_not_empty "Please enter the encryption key: " "" RESULT
            EKEY="${RESULT}"
            validate_variable "DISK_ENCRYPTION_KEY" "${CONFIG_FILE}" "${EKEY}"
            export DISK_ENCRYPTION_KEY
        else
            validate_variable "DISK_ENCRYPTION_KEY" "${CONFIG_FILE}" "${EKEY}"
            export DISK_ENCRYPTION_KEY
        fi
    fi

    # EDB YUM UserName
    CHECK=$(check_variable "YUM_USERNAME" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_string_not_empty "Please provide EDB Yum Username: " "" RESULT
        YUM_USERNAME="${RESULT}"
    fi
    validate_variable "YUM_USERNAME" "${CONFIG_FILE}" "${YUM_USERNAME}"
    export YUM_USERNAME

    # EDB YUM Password
    CHECK=$(check_variable "YUM_PASSWORD" "${CONFIG_FILE}")
    if [[ "${CHECK}" = "not_exists" ]] || [[ "${CHECK}" = "exists_empty" ]]
    then
        RESULT=""
        validate_password_not_empty "Please provide EDB Yum Password: " "" RESULT
        YUM_PASSWORD="${RESULT}"
    fi
    validate_variable "YUM_PASSWORD" "${CONFIG_FILE}" "${YUM_PASSWORD}"
    export YUM_PASSWORD

    set -u

    process_log "set all parameters"
    source ${CONFIG_FILE}
}

function aws_show_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    SHOW="$(echo cat ${CONFIG_FILE})"
    eval "$SHOW"

    process_log "showed aws project config details"
}

function azure_show_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    SHOW="$(echo cat ${CONFIG_FILE})"
    eval "$SHOW"

    process_log "showed azure project config details"
}

function gcloud_show_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    SHOW="$(echo cat ${CONFIG_FILE})"
    eval "$SHOW"

    process_log "showed gcloud project config details"
}

function aws_update_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/aws/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    EDIT="$(echo vi ${CONFIG_FILE})"
    eval "$EDIT"

    process_log "edited aws project config details"
}

function azure_update_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/azure/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    EDIT="$(echo vi ${CONFIG_FILE})"
    eval "$EDIT"

    process_log "edited azure project config details"
}

function gcloud_update_config_file()
{
    local PROJECT_NAME="$1"
    local CONFIG_FILE="${PROJECTS_DIRECTORY}/gcloud/${PROJECT_NAME}/${PROJECT_NAME}.cfg"

    EDIT="$(echo vi ${CONFIG_FILE})"
    eval "$EDIT"

    process_log "edited gcloud project config details"
}

function aws_list_projects()
{
    echo "AWS Terraform Projects:"
    cd ${DIRECTORY}/terraform/aws || exit 1
    LIST_PROJECTS="$(echo terraform workspace list)"
    eval "$LIST_PROJECTS"

    process_log "listed all aws projects"
}

function azure_list_projects()
{
    echo "Azure Terraform Projects:"
    cd ${DIRECTORY}/terraform/azure || exit 1
    LIST_PROJECTS="$(echo terraform workspace list)"
    eval "$LIST_PROJECTS"

    process_log "listed all azure projects"
}

function gcloud_list_projects()
{
    echo "GCloud Terraform Projects:"
    cd ${DIRECTORY}/terraform/gcloud || exit 1
    LIST_PROJECTS="$(echo terraform workspace list)"
    eval "$LIST_PROJECTS"

    process_log "listed all GCloud projects"
}

function aws_switch_projects()
{
    local PROJECT_NAME="$1"

    cd ${DIRECTORY}/terraform/aws || exit 1
    SWITCH_PROJECT="$(echo terraform workspace select ${PROJECT_NAME})"
    eval "$SWITCH_PROJECT"

    process_log "switched to aws project: ${PROJECT_NAME}"
}

function azure_switch_projects()
{
    local PROJECT_NAME="$1"

    cd ${DIRECTORY}/terraform/azure || exit 1
    SWITCH_PROJECT="$(echo terraform workspace select ${PROJECT_NAME})"
    eval "$SWITCH_PROJECT"

    process_log "switched to azure project: ${PROJECT_NAME}"
}

function gcloud_switch_projects()
{
    local PROJECT_NAME="$1"

    cd ${DIRECTORY}/terraform/gcloud || exit 1
    SWITCH_PROJECT="$(echo terraform workspace select ${PROJECT_NAME})"
    eval "$SWITCH_PROJECT"

    process_log "switched to gcloud project: ${PROJECT_NAME}"
}
