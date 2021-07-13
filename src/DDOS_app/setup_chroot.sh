#!/bin/bash

# https://pc-freak.net/blog/nginx-webserver-increase-security-putting-websites-linux-jails-howto/

cd /opt
export DIR_N=/opt/ddps_ui_chroot_rw

rm -fr ddps_ui_chroot_rw ddps_ui_chroot_ro

test -d ddps_ui_chroot_rw || mkdir ddps_ui_chroot_rw	# make chroot here, dont use it
test -d ddps_ui_chroot_ro || mkdir ddps_ui_chroot_ro	# make a bind mount here pointing to chroot

# should start by remove anything below $DIR_N

# Create directory structure
mkdir -p $DIR_N/usr/sbin
mkdir -p $DIR_N/usr/bin
mkdir -p $DIR_N/etc
mkdir -p $DIR_N/dev
mkdir -p $DIR_N/var
mkdir -p $DIR_N/usr
mkdir -p $DIR_N/tmp
mkdir -p $DIR_N/lib
mkdir -p $DIR_N/lib64
mkdir -p $DIR_N/usr/lib64
mkdir -p $DIR_N/usr/lib/x86_64-linux-gnu
mkdir -p $DIR_N/lib/x86_64-linux-gnu

mkdir -p $DIR_N/var/tmp

# Make devices
test -c $DIR_N/dev/null    || /bin/mknod -m 0666 $DIR_N/dev/null c 1 3
test -c $DIR_N/dev/random  || /bin/mknod -m 0666 $DIR_N/dev/random c 1 8
test -c $DIR_N/dev/urandom || /bin/mknod -m 0444 $DIR_N/dev/urandom c 1 9

# Set mode
chmod 0666 $DIR_N/dev/null $DIR_N/dev/random $DIR_N/dev/urandom
chmod 1777 $DIR_N/tmp $DIR_N/var/tmp

# Set owner and group
chown -R root:root $DIR_N

# Install nginx application
/bin/cp -arf /usr/sbin/nginx $DIR_N/usr/sbin/nginx

# Install nginx shared object dependencies
# linux-vdso:
#	https://blog.packagecloud.io/eng/2017/03/08/system-calls-are-much-slower-on-ec2/ 
ldd $DIR_N/usr/sbin/nginx|
	awk '{ print match($3, /[^ ]/) ? $3 : $1 }'|sed '/linux-vdso/d'|while read DEP
	do
		REALFILE=$( realpath ${DEP} )
		DIRNAME=$( dirname ${DEP} )
		FILENAME=$( basename ${DEP} )
		/bin/cp -af ${REALFILE} $DIR_N/${DIRNAME}
		ln -sf ${REALFILE} $DIR_N/${DEP}
	done


# fake /etc/files

for FILE in /etc/{group,services,shells,localtime,nsswitch.conf,conf,protocols,ld.so.cache,ld.so.conf,resolv.conf,host.conf}
do
	cp -rfH $FILE $DIR_N//etc
done

cat << EOF > $DIR_N/etc/hosts
127.0.0.1	localhost
127.0.1.1	$(hostname)

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

cat << EOF > $DIR_N/etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd:/usr/sbin/nologin
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd:/usr/sbin/nologin
systemd-timesync:x:102:104:systemd Time Synchronization,,,:/run/systemd:/usr/sbin/nologin
messagebus:x:103:106::/nonexistent:/usr/sbin/nologin
syslog:x:104:110::/home/syslog:/usr/sbin/nologin
systemd-coredump:x:999:999:systemd Core Dumper:/:/usr/sbin/nologin
postgres:x:114:121:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/bash
EOF
cat << EOF > $DIR_N/etc/shadow
root:!:18559:0:99999:7:::
daemon:*:18474:0:99999:7:::
bin:*:18474:0:99999:7:::
sys:*:18474:0:99999:7:::
lp:*:18474:0:99999:7:::
mail:*:18474:0:99999:7:::
news:*:18474:0:99999:7:::
uucp:*:18474:0:99999:7:::
proxy:*:18474:0:99999:7:::
www-data:*:18474:0:99999:7:::
backup:*:18474:0:99999:7:::
nobody:*:18474:0:99999:7:::
systemd-network:*:18474:0:99999:7:::
systemd-resolve:*:18474:0:99999:7:::
systemd-timesync:*:18474:0:99999:7:::
messagebus:*:18474:0:99999:7:::
syslog:*:18474:0:99999:7:::
systemd-coredump:!!:18559::::::
postgres:*:18617:0:99999:7:::
EOF
chmod 0640 $DIR_N/etc/shadow

cat << EOF > $DIR_N/etc/group
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:syslog,vagrant
tty:x:5:syslog
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
www-data:x:33:
src:x:40:
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
systemd-journal:x:101:
systemd-network:x:102:
systemd-resolve:x:103:
systemd-timesync:x:104:
messagebus:x:106:
syslog:x:110:
systemd-coredump:x:999:
postgres:x:121:
EOF

mkdir -p  ${DIR_N}/etc/ld.so.conf.d 
cp -ar /etc/ld.so.conf.d/* ${DIR_N}/etc/ld.so.conf.d/




exit 0

tree ${DIR_N}


