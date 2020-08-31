edb.postgres.sqlexec
=========

This Ansible Galaxy Role Executes SQL Statements for Postgres versions: 10, 11 and 12 on EC2 Instances previously configured on AWS.

Requirements
------------

The dependencies that are required prior to executing this role are:
1. 01-prereqs
2. 02-cluster
3. 03-install
4. 04-replication

Role Variables
--------------

When executing the role via ansible there are two required variables:
* OS
* PG_VERSION

Dependencies
------------

The edb.postgres.sqlexec role does not have any dependencies on any other roles.

Example Playbook
----------------

Below is an example of how to use the: edb.postgres.sqlexec role:

    - hosts: localhost
      name: Execute SQL Statements on Postgres SQL Cluster
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
            name: edb.postgres.sqlexec
          with_dict: "{{ hosts }}"

License
-------

BSD

Author Information
------------------

Author: 
* Doug Ortiz
* EDB Postgres DevOps
* doug.ortiz@enterprisedb.com
* www.enterprisedb.com
