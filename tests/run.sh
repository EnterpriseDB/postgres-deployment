#!/bin/bash -eux

export EDB_DEPLOY_CLOUD_VENDOR=${EDB_DEPLOY_CLOUD_VENDOR:="aws"}
export EDB_DEPLOY_CLOUD_REGION=${EDB_DEPLOY_CLOUD_REGION:="us-east-2"}
export EDB_DEPLOY_PG_TYPE=${EDB_DEPLOY_PG_TYPE:="PG"}
export EDB_DEPLOY_PG_VERSION=${EDB_DEPLOY_PG_VERSION:="13"}
export EDB_DEPLOY_RA=${EDB_DEPLOY_RA:="EDB-RA-1"}
export EDB_DEPLOY_EDB_CREDENTIALS=${EDB_DEPLOY_EDB_CREDENTIALS:="user:password"}
export EDB_DEPLOY_EFM_VERSION=${EDB_DEPLOY_EFM_VERSION:="4.2"}
export EDB_GOOGLE_ACCOUNTS_FILE=${GOOGLE_ACCOUNTS_FILE:=~/accounts.json}

COMPOSE_SERVICE="test-aws"
if [ $EDB_DEPLOY_CLOUD_VENDOR = "azure" ]
then
	COMPOSE_SERVICE="test-azure"
fi
if [ $EDB_DEPLOY_CLOUD_VENDOR = "gcloud" ]
then 
	COMPOSE_SERVICE="test-gcloud"
	cp $EDB_GOOGLE_ACCOUNTS_FILE data/accounts.json
fi

# Docker compose command
docker compose up \
	--exit-code-from ${COMPOSE_SERVICE} \
	--abort-on-container-exit ${COMPOSE_SERVICE} \
	--remove-orphans