
# Using the API with fastnetmon

The following is an (incomplete) example of using the API with the community edition of [Fastnetmon](https://github.com/pavel-odintsov/fastnetmon).

The community edition of fastnetmon is installed as [this guide](https://fastnetmon.com/install/). On ubuntu 20.04 it is also possible to just do `sudo apt-get update -y; apt-get install fastnetmon -y`.

Fastnetmon logs to `/var/log/fastnetmon.log`, and may be monitored in real time with `fastnetmon_client`.

The configuration files are

  - `/etc/fastnetmon.conf`: documented configuration file. Set path to the notification script here.
  - `/etc/networks_list`: lines with CIDRs that will be monitored
  - `/etc/networks_whitelist`: lines with CIDRs from which attacks will be ignored

The service must be restarted after changes with `sudo service fastnetmon restart`.

The community edition may call a _notification script_ which takes 4 argument on the command line and a text `tcpdump` on `stdin`.

The 4 arguments are the _client_ip_as_string_ _data_direction_ _pps_ and _action_. They are described in the documentation.

The dump may not contain all tcpdump fields (ie. not all ICMP types) and look like this (source is faked):

```bash
2017-04-03 12:03:02.276094 142.108.168.46:10972 > 10.0.XXX.XXX:0 protocol: udp frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
10.0.XXX.XXX:0 < 15.241.70.39:11298 60 bytes 1 packets
2017-04-03 12:03:02.276097 47.177.234.194:10973 > 10.0.XXX.XXX:0 protocol: udp frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
10.0.XXX.XXX:0 < 246.168.108.52:11298 60 bytes 1 packets
...
2017-03-27 15:32:03.385767 231.14.114.129:0 > 10.0.XXX.XXX:0 protocol: icmp frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
2017-03-27 15:32:03.385769 180.216.248.84:0 > 10.0.XXX.XXX:0 protocol: icmp frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
2017-03-27 15:32:03.385772 222.231.209.226:0 > 10.0.XXX.XXX:0 protocol: icmp frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
```
It is possible to distill a rule which matches the attack to a fair degree, then convert it to an action which can be enforced using the API.

The script [`decode-attack.pl`](decode-attack.pl) attempts do do so and could be used as the `notification` script. `decode-attack.pl` calls [`client-api`](client-api) to connect to the API, both scripts should be installed in `/usr/local/bin` and are just proof of concepts.

The login and password in `client-api` must be changed, also notice that in Vagrant the api uses http not https.


