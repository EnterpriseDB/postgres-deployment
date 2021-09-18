#!/bin/bash -eux

# Installation of the require packages
dnf install epel-release -y
dnf install python3 \
	python3-pip \
	gcc \
	python3-devel \
	wget \
	unzip \
	tar \
	openssh \
	openssh-clients \
	-y

python3 -m pip install pip --upgrade
python3 -m pip install setuptools_rust
python3 -m pip install virtualenv pytest pytest-testinfra paramiko

# Install edb-deployment from the sources
python3 -m pip install /workspace --upgrade --use-feature=in-tree-build

# Prepare SSH env.
eval $(ssh-agent -s)
mkdir -p /root/.ssh
chmod 0700 /root/.ssh

# Make a copy of the directory containing Azure credentials
if [ $EDB_DEPLOY_CLOUD_VENDOR = "azure" ]
then
	mkdir -p /root/.azure
	cp -r /root/.azure.ro/* /root/.azure/.
fi

# Tests execution
py.test \
	-o log_file="/workspace/tests/pytest.log" \
	-o log_file_level="INFO" \
	-v \
	/workspace/tests/test_edb-deployment.py
