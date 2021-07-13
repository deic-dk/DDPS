
## Template rules

### Server protection
---
**Template name**: Standard Web server
**Description**: Block everything but TCP port 80 and 443 to CIDR
**Arguments**: CIDR, valid from, valid to
**Rule(s) description**:

  1. block all fragments
  2. block protocol range 1-5, 7-255
  3. block dest. port range 0-79, 81-432, 434-65536

**Actual rules**:

  1. `destinationprefix [CIDR] fragmentencoding [is-fragment dont-fragment first-fragment last-fragment] action [discard] description [description]`
  2. `destinationprefix [CIDR] protocolnumber [<=5&>=7] action [discard] description [description]`
  3. `destinationprefix [CIDR] destinationport [<=79, >=81&<=432, >=434] description [description]`

---
**Template name**: SMTP server
**Description**: Block everything but TCP port 25
**Arguments**: CIDR, valid from, valid to
**Rule(s) description**:

  1. block all fragments
  2. block protocol range 1-5, 7-255
  3. block dest. port range 0-23, 26-65536

**Actual rules**:

  1. `destinationprefix [CIDR] fragmentencoding [is-fragment dont-fragment first-fragment last-fragment] action [discard] description [description]`
  2. `destinationprefix [CIDR] protocolnumber [<=5&>=7] action [discard] description [description]`
  3. `destinationprefix [CIDR] destinationport [<=23, >=26] description [description]`

---
**Template name**: DNS domain server
**Description**: Block everything but UDP port 53
**Arguments**: CIDR, valid from, valid to
**Rule(s) description**:

  1. block all fragments
  2. block protocol range 1-15, 17-255
  3. block dest. port range 0-79, 81-432, 434-65536

**Actual rules**:

  1. `destinationprefix [CIDR] fragmentencoding [is-fragment dont-fragment first-fragment last-fragment] action [discard] description [description]`
  2. `destinationprefix [CIDR] protocolnumber [<=16&>=18] action [discard] description [description]`
  3. `destinationprefix [CIDR] destinationport [<=52, >=54] description [description]`

---
**Template name**: NTP time server
**Description**: Block everything but NTP port 123
**Arguments**: CIDR, valid from, valid to
**Rule(s) description**:

  1. block all fragments
  2. block protocol range 1-16, 18-255
  3. block dest. port range 0-122, 124-65536

**Actual rules**:

  1. `destinationprefix [CIDR] fragmentencoding [is-fragment dont-fragment first-fragment last-fragment] action [discard] description [description]`
  2. `destinationprefix [CIDR] protocolnumber [<=16&>=18] action [discard] description [description]`
  3. `destinationprefix [CIDR] destinationport [<=122, >=124] description [description]`

## Amplification protection

Rules for protection against DNS, Memcache and NTP amplification attacks.

More to follow, notes to UNINTH below.

[Memcache](https://en.wikipedia.org/wiki/Memcached)

UDP source port 11211

  - https://blog.cloudflare.com/memcrashed-major-amplification-attacks-from-port-11211/
  - https://www.cloudflare.com/learning/ddos/memcached-ddos-attack/
  - https://www.akamai.com/uk/en/resources/our-thinking/threat-advisories/ddos-reflection-attack-memcached-udp.jsp
  - https://blog.apnic.net/2018/03/26/understanding-the-facts-of-memcached-amplification-attacks/
    her NTT recommends adding memcached UDP/11211 to the same “exploitable ports” list as NTP, CHARGEN and SSDP
  


