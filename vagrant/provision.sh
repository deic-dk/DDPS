#! /bin/bash
#
function add_ansible_and_setup_trust()
{
	# The ubuntu bento/20.04 box does not not allow password based ssh login so setting
	# up trust using ansible only requires first changing sshd_config (shell), followed
	# by key creating and adding trust  between the two ansible users,  and storing the
	# in an ansible-vault, kbut for now this is good enough:
	# SSH key created ahead with
	# ssh-keygen -t ED25519 -f id_ddps_key_ed25519 -N '' # keys doesn't have password, so
	# no -a 200 
	
id_ddps_key_ed25519="-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACCLbjNm9iwcEonx7ylzRNxy99qY6XuWJ1QDMu7VCAji9wAAAJh2iL2xdoi9
sQAAAAtzc2gtZWQyNTUxOQAAACCLbjNm9iwcEonx7ylzRNxy99qY6XuWJ1QDMu7VCAji9w
AAAEC1d9uxcIKY3FBrj1F0qAG2AcAocr9ZJKUd7DknogaXgItuM2b2LBwSifHvKXNE3HL3
2pjpe5YnVAMy7tUICOL3AAAAE3VuaW50aEBtYWNudGgubG9jYWwBAg==
-----END OPENSSH PRIVATE KEY-----"

id_ddps_key_ed25519_pub="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItuM2b2LBwSifHvKXNE3HL32pjpe5YnVAMy7tUICOL3 ansible@localhost"

	getent passwd ansible || {
		echo adding ansible on both hosts assigning same ssh key to both hosts will only use from ww1 to fw1 ...
		adduser --uid 8888 --home /home/ansible --shell /bin/bash --gecos "ansible user" --disabled-password ansible
		usermod -a -G sudo	ansible
		mkdir -p /home/ansible/.ssh
		echo "$id_ddps_key_ed25519_pub" >> /home/ansible/.ssh/authorized_keys
		echo "$id_ddps_key_ed25519_pub" > /home/ansible/.ssh/id_ed25519.pub
		echo "$id_ddps_key_ed25519" > /home/ansible/.ssh/id_ed25519
		for my_public_key in ${my_public_keys}
		do
			if [ -f ${my_public_key} ]; then
				cat "${my_public_key}" >> /home/ansible/.ssh/authorized_keys
			fi
		done
		chown -R ansible /home/ansible/.ssh/
		chmod 700 /home/ansible/.ssh /home/ansible/.ssh/*
		# You are required to change your password immediately ...
		sed -i 's/^ansible:.*$/ansible:*:16231:0:99999:7:::/' /etc/shadow
		echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible
		echo 'sudo whoami'|su - ansible
	}

	case $( hostname -f ) in
		ww1.ddps.deic.dk)
			test -d /root/.ssh/ || mkdir /root/.ssh/
			find /root -type d -print0 | xargs -0 chmod 755
			find /root -type f -print0 | xargs -0 chmod 644
			echo "${id_ddps_key_ed25519}" >> /root/.ssh/id_ed25519
			echo "${id_ddps_key_ed25519_pub}" >> /root/.ssh/id_ed25519.pub
			chmod -R 700 /root
			chmod 600  /root/.ssh/id_ed25519 /root/.ssh/id_ed25519.pub
			;;
		fw1.ddps.deic.dk)
			test -d /root/.ssh/ || mkdir /root/.ssh
			find /root -type d -print0 | xargs -0 chmod 755
			find /root -type f -print0 | xargs -0 chmod 644
			echo "${id_ddps_key_ed25519}" >> /root/.ssh/id_ed25519
			echo "${id_ddps_key_ed25519_pub}" >> /root/.ssh/authorized_keys
			chmod -R 700 /root
			chmod 600  /root/.ssh/id_ed25519 /root/.ssh/authorized_keys
			;;
		*)	echo "unknown hostname $( hostname -f )"; exit 127
			;;
	esac
}


#
# main
#
# add public key for operator (you)
my_public_keys=$( echo ~/.ssh/id*pub )

case $(hostname -f ) in
	ww1.ddps.deic.dk)

	apt update	# required or the next command fails
	apt install --yes	python3 python3-pip python3-venv python3-dev	\
						build-essential python3-wheel python3-apt
	# apt-get install -y python3.6 python3-pip python3-venv python3-dev
	# \
	# build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev	\
	# zlib1g-dev

	# setup venv here
	export VENVDIR=/opt/ansible_venv
	# prevent varnings 'parent directory is not owned ... current user'
	export HOME=/root

	if [ ! -f ${VENVDIR}/bin/activate ]; then
		# The following is not so elegant but patching /etc/profile or
		# /etc/bash.bashrc has no effect in the vagrant box
		# The virtual environment needs access to the system site-packages dir
		# in order for the python3-apt package to be found.
		# Having the package manager outside the language is odd
		python3 -m venv ${VENVDIR} --system-site-packages
		. ${VENVDIR}/bin/activate
		pip3 install --upgrade pip
		cat <<-EOF > ${VENVDIR}/requirements.txt
	wheel	# latest
	ansible	# latest version
EOF

		# Install required modules
		pip3 install -r ${VENVDIR}/requirements.txt
		# ansible galaxy commands here
		:
		# ansible-galaxy collection install community.general
		:

	fi

	add_ansible_and_setup_trust

	# The following is not so elegant but patching /etc/profile or /etc/bash.bashrc has
	# no effect nor has adding '*.sh' files to /etc/profile.d;  they are being ignored.
	# This works somehow, but doesn't scale
	for f in $( find /root/ /home/ -name .bashrc )
	do
		if (grep -q 'bin/activate' ${f}  ); then
			:
		else
			cat <<-EOF >> ${f}
if [ -f ${VENVDIR}/bin/activate ]; then
	. ${VENVDIR}/bin/activate
fi
EOF
		fi
	done

	# create ansible.pub based on the pub key in the script + your public key(s)
	# this has to be done as the users.yml playbook will use it
	cat /home/ansible/.ssh/authorized_keys > /ansible/group_vars/all/keys/ansible.pub

	echo '. /opt/ansible_venv/bin/activate; cd /ansible; ansible-playbook  -i inventory /ansible/playbooks/ping.yml'|su -l ansible
	echo '. /opt/ansible_venv/bin/activate; cd /ansible; ansible-playbook  -i inventory /ansible/playbooks/provision.yml -e env=vagrant'|su -l ansible

	;;
	fw1.ddps.deic.dk)
		add_ansible_and_setup_trust
	;;
	*) echo unknown host $(hostname -f)
	;;
esac

