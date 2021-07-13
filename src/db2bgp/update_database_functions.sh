#! /usr/bin/env bash

echo -n 'Stopping db2bgp service ... '
sudo service db2bgp stop && echo done

# Terminate other connections with

sudo rm -f /tmp/terminate_other_connections.sql /tmp/ddps_endpoints.sql

cat << 'EOF' > /tmp/terminate_other_connections.sql
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'flows'
   AND pid <> pg_backend_pid();
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'flows';
EOF

cp ./ddps_endpoints.sql /tmp/ddps_endpoints.sql

echo -n 'Terminating all database connections ... '
sudo su - postgres -c 'psql -a --set ON_ERROR_STOP=OFF -d flows -f /tmp/terminate_other_connections.sql' &>/dev/null 
echo 'done'
echo -n 'sleeping .'
for (( c=1; c<=5; c++ ))
do
	echo -n .
	sleep 1
done
echo done

echo -n 'Applying databsae functions from ddps_endpoints.sql ... '
sudo su - postgres -c 'psql -v ON_ERROR_STOP=ON  -d flows -f /tmp/ddps_endpoints.sql' &>/dev/null
echo "done, exit status $?"

echo -n 'sleeping .'
for (( c=1; c<=5; c++ ))
do
	echo -n .
	sleep 1
done
echo done


echo -n 'restarting service db2bgp ... '
sudo service db2bgp start && echo done

