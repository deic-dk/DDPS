
# Users

Rightish user account management on OpenBSD and Linux.

Users are defined as

  - ** managed users**  are defined in `inventory/group_vars/all/users.yml` (name, group, comment, shell, sudo, no password): These accounts will be added if absent.
  - ** absent users**  that should be deleted if present are defined in `inventory/group_vars/all/deleteusers.yml` (former employees)
  - ** ignored users**  that may or may not exist on a system are defined in `inventory/group_vars/all/default_users.yml` the  accounts will be ignored
  - ** required users**  system users like (`ansible`) which must exists, and are defined in `defaults/main.yml` which will be created with minimal information (username only)

All managed users must have a _public ssh key_ defined in `files/keys`.

The password for managed uses will be set to `'*'`, effective disabling console and ssh login with password

Users with `become: yes` will be added to `sudoers` on Linux and `doas.conf` on OpenBSD without requiring password for privilege escalation, and will in the future also be able to login with ssh as `root`

## Exceptions and snowflakes

Systems which requires extra users may have a list of users which are ignored in `include_vars: "{{ inventory_dir }}/host_vars/{{ inventory_hostname }}/default_users.yml"`, defined as `'default_users: ['nobody', 'provision', 'ubuntu', 'vagrant', 'upload' ]'`.

## Requirements

Bootstrapped and provisioned hosts.

## Role Variables

See `inventory/group_vars/all/users.yml` which should be made from in Netbox tenants data. Same goes for `inventory/group_vars/all/deleteusers.yml`

## Dependencies

The role is aware that Linux and OpenBSD uses different tools for privilege escalation.

## Example Playbook

	- hosts: servers firewalls
	   name: User provisioning
	   gather_facts: yes
	   roles:
		 - users

## License

BSD

## Author Information

NTH
