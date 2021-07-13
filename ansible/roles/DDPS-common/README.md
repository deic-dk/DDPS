Common
======

Bootstrap an Ubuntu 18.04 or 20.04 in a vagrant environment, where trust has been established between the control node and the other hosts

Requirements
------------

See the provision.sh in directory vagrant

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

N/A

Example Playbook
----------------

See playbooks/provision.yml

---
- hosts: all
  name: Provision Ubuntu
  gather_facts: yes
  roles:
  - common


License
-------

BSD

Author Information
------------------

NTH
