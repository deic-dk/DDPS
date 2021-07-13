
## Add rule help

Rules may be added with `db2bgp.pl -a 'expression'`.

Parameters that has a default value may be omitted and the default will be value used.     
All applied parameters must have the format var: [value], please encapsulate line in single quotes


| variable          | description                                                           | Default value if any              |
| ---               | ---                                                                   | ---                               |
| validfrom         | timestamp with time zone: YYYY-mm-dd HH:MM:SS CET                     | time now                          |
| expireafter       | minutes until expire                                                  | 10 min, lower values not accepted |
| direction         | direction (in or out)                                                 | in                                |
| destinationport   | =80 =443 >=10&<=100 ... range 0-65536                                 | any                               |
| sourceport        | =80 =443 >=10&<=100 ... range 0-65536                                 | any                               |
| icmptype          | =0 =3 ..                range 0-255                                   | any                               |
| icmpcode          | =0 =3 ..                range 0-255                                   | any                               |
| packetlength      | =64 =1470 >=10&<=100    range 64-9000                                 | any                               |
| dscp              | =0 ...                  range 0-63                                    | any                               |
| description       | Descriptive text                                                      |                                   |
| destinationprefix | One valid CIDR within our constituency                                |                                   |
| sourceprefix      | One valid CIDR within our constituency                                | 0.0.0.0/0                         |
| action            | accept, discard, rate-limit 9600, rate-limit 19200, rate-limit 38400  | discard                           |
| fragmentencoding  | is-fragment dont-fragment first-fragment last-fragment not-a-fragment | any                               |
| tcpflags          | fin syn rst push ack urgent                                           | any                               |
| protocolnumber    | =0 =3 ...               range 0-255                                   | any                               |

### Examples

_lines has been wrapped for readability_.

#### Blok access to `TCP port 22` on `10.0.0.1` next `120 min` from `169.254.0.0/16`

`````bash
db2bgp.pl -a '
direction [in] sourceprefix [169.254.0.0/16] destinationprefix [10.0.0.1/32]
protocolnumber [=6] destinationport [=22] expireafter [120]
description [block SSH access, newer know who they are] action [discard]'
`````

#### Blok UDP fragments to 10.0.0.1 from _any_ next 7 days

 `````bash
db2bgp.pl -a '
direction [in] protocolnumber [=17] destinationprefix [10.0.0.1/32]
fragmentencoding [is-fragment dont-fragment first-fragment last-fragment not-a-fragment]
expireafter [604800] description [block all fragments] action [discard]'
`````

#### Blok GRE from _any_ to 10.0.0.1/24 next 10 min

`````bash
db2bgp.pl -a '
direction [in] protocolnumber [=47] destinationprefix [10.0.0.0/24]
description [block GRE] action [discard]'
`````
