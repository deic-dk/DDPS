Postgres
=========

Configure postgres and apply example data (Vagrant only) on the host ww1.ddps.deic.dk

Requirements
------------

See playbook

Role Variables
--------------

After package installation and configuration, an SQL dump is applied

Dependencies
------------

Dump made with

	echo 'pg_dumpall --clean --if-exists | gzip -v9 > /tmp/dumpall-with-oids.gz' | su - postgres

Example Playbook
----------------

See playbooks/

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

NTHA
