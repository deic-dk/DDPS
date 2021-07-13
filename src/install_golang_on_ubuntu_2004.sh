#!/bin/bash

# this gives 1.16.2
# sudo apt install -y golang
# or for the latest

LATEST="1.16.4"	# Check latest at https://golang.org/dl/

case $(whoami) in
	"root")	:
		;;
	*)	echo run as root
		exit
		;;
esac
apt -yq remove golang >/dev/null 2>&1
apt -yq autoremove >/dev/null 2>&1

if type go >/dev/null 2>&1; then
	VERSION=$( go version|sed 's/.*version//; s/^ //; s/ .*//; s/go//g' )
else
	VERSION=""
fi

echo you must check if $LATEST is latest on https://golang.org/dl/ yourself
case $VERSION in
	"$LATEST")	echo "latest version $LATEST installed, see script"
	      	 	exit 0
		;;
	"")	echo "go not installed"
		;;
	*)	echo "latest version is $LATEST, $VERSION installed, please remove /usr/local/go and try again"
		exit 1
		;;
esac

echo will exit if /usr/local/go found
test -d /usr/local/go && exit
wget -N https://golang.org/dl/go${LATEST}.linux-amd64.tar.gz
tar -xzvf  go${LATEST}.linux-amd64.tar.gz -C /usr/local/

grep /usr/local/go/bin /etc/environment ||echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/go/bin"' > /etc/environment

rm -f go${LATEST}.linux-amd64.tar.gz

cat << 'EOF' > /usr/local/etc/cmod/modulefiles/go
$(
	echo "prepend-path	GOPATH	\$HOME/go"
	echo "prepend-path	GOROOT	/usr/local/go"
	echo "prepend-path	PATH	PATH:\$GOPATH/bin"
	echo "prepend-path	PATH	PATH:\$GOROOT/bin"
	echo "prepend-path	GOBIN	\$GOROOT/bin"
exit 0)
EOF

sed -i '/module try-add go/d' /usr/local/etc/cmod/modulefiles/default
echo 'module try-add go' >> /usr/local/etc/cmod/modulefiles/default

# non-root, non sudoers, non module users
echo 'export PATH="$PATH:/usr/local/go/bin"' > /etc/profile.d/go.sh
test -d /etc/sudoers || { 
	cp /etc/sudoers /etc/sudoers.org
}
cat /etc/sudoers.org|sed 's|secure_path.*|secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/local/go/bin"|g' > /etc/sudoers
chmod 0440 /etc/sudoers
chown root:root /etc/sudoers

# yes it could also be installed with ansible, I know
