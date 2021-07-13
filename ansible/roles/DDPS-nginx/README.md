DDPS NGINX
==========

A NGINX installation for DDPS vagrant image. Notice the difference between -e env=prod and absent -e or -e env=vagrant.

Requirements
------------


Role Variables
--------------

This role does only provide what is required for bringing DDPS up in a test environment. Hardening NGINX is not done, please see eg https://galaxy.ansible.com/dev-sec/nginx-hardening later.

Dependencies
------------

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

NTH
