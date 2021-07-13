
## GUI rule creation

Rules made for being implemented as [BGP flowspec](https://tools.ietf.org/html/rfc5575) differs from traditional firewall implementations, so

  - The rule order is _not always predictable_
  - The rules are for _volumetric mitigation_
  - Try to match as precise as possible
  - Rules are _not permanent_ but volatile and _will always expire_
  - Please describe the motivation of the rule

[more examples on github](Below are two examples)

### Mitigating NTP amplification attack

NTP amplification attack is described [here](https://www.imperva.com/learn/application-security/ntp-amplification/). The values below are from [this article](http://nabcop.org/index.php/DDoS-DoS-attack-BCOP), with a [local copy here](docs/DDoS-DoS-attack-BCOP.md).

| Option              | Value                                                        |
| ------------------- | ------------------------------------------------------------ |
| Description         | **Block NTP amplification** notice match on _source port_    |
| Source Address      | _leave empty_                                                |
| Destination Address | `a.b.c.d/e`                                                  |
| Protocol            | `UDP`                                                        |
| Src. Port           | 123                                                          |
| Dst. Port           | _leave empty_                                                |
| Packet Length       | 468                                                          |
| Fragment Type       | _leave empty_                                                |
| Then Actions        | _discard_                                                    |
| From Date           | _default from now_                                           |
| Expiry Date         | _sometime in the future_                                     |

### Protecting a web-server (http and https)

While it is tempting to create two rules allowing http and https traffic and one blocking everything this approach is _not guaranteed to work_, as while the rules may be created in the correct order _they are not guaranteed to be implemented in the same order_. At least 10 rules are required. Also notice this only shields against volumetric attacks.

  1. First create **4 rules to block fragments**: create 4 similar _discard_-rules for the same CIDR, one for each _fragment type_ (`is-fragment dont-fragment first-fragment last-fragment`), and leave `protocol`, `source address` blank.
  1. Next create **3 rules to block non-TCP protocols**: create (at least) one _discard_-rule for each protocol `ICMP`, `UDP` and `GRE`. To match `GRE` select _protocol other_ and type `47` in protocol number. There are other IP protocols that may be used for DDoS attack, but GRE and UDP are the most widespread according to [Akamai state of the Internet Q2-2017](https://www.akamai.com/de/de/multimedia/documents/state-of-the-internet/q2-2017-state-of-the-internet-security-report.pdf).
  1. Finally create **3 rules to block other TCP ports than 80 and 443**: create one rule that matches protocol TCP and destination port `0-79`, one rule that matches destination port range `81-442` and one rule that matches destination port range `>444`. 

Notice the server is _still vulnerable to [syn flooding](https://en.wikipedia.org/wiki/SYN_flood)_ which should be addressed on the server itself. The same goes for application layer attacks (e.g. [Slowloris](https://en.wikipedia.org/wiki/Slowloris_(computer_security)), [R-U-Dead-Yet](https://en.wikipedia.org/wiki/R-U-Dead-Yet) and [ReDoS](https://en.wikipedia.org/wiki/ReDoS)).

Protecting other similar services is done the same way.

