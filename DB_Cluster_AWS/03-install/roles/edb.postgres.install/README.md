edb.postgres.install
=========

This Ansible Galaxy Role Installs and Deploys Postgres versions: 10, 11 and 12 on EC2 Instances previously configured on AWS.

Requirements
------------

The dependencies that are required prior to executing this role are:

1. 01-prereqs
2. 02-cluster
3. 03-install

Role Variables
--------------

When executing the role via ansible there are two required variables:

* OS
* PG_VERSION

The rest of the variables are available in the:
* roles/edb.postgres.replication/defaults/main.yml

Dependencies
------------

The edb.postgres.install role does not have any dependencies on any other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:



    - hosts: localhost
      name: Install Postgres on AWS EC2 Instances
      connection: local
      become: true
      gather_facts: yes

      vars_files:
        - hosts.yml

      pre_tasks:
        - set_fact:
            OS: OS
            PG_VERSION: PG_VERSION
          with_dict: "{{ hosts }}"
      tasks:
        - name: Iterate through role with items from hosts file
          include_role:
            name: edb.postgres.install
          with_dict: "{{ hosts }}"

License
-------

BSD

Author Information
------------------
Author: 
* Doug Ortiz
* EDB Postgres 
* DevOps 
* doug.ortiz@enterprisedb.com www.enterprisedb.com
