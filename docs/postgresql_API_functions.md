# Functions for the API

There are some non-portable [Postgresql](https://www.postgresql.org) functions to be used primarily by the _API_.

The functions are defined in the document `ddps_endpoints.sql` and may be installed with the commands listed in the beginning of the document [how-to-use-the-functions](src/db2bgp/how-to-use-the-functions.md) located in [src](/src/db2bgp) and tested with `make test`.

  - Stop the background service if running: `service db2bgp stop`
  - Terminate other database connections by executing the SQL below as user `postgres`:
    `````SQL
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'flows'
    AND pid <> pg_backend_pid();
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'flows';
    `````
  - Apply the functions (may be done several times) with 
    `````bash
echo "psql -v ON_ERROR_STOP=ON -d flows < ./ddps_endpoints.sql |sudo su - postgres
    `````
  - Start the back ground process again:
    `service db2bgp start`

The functions are

  - `ddps_login(usr,clearpw) return adminid, customerid`: a login function to validate the combination of username and password
  - `ddps_listrules(adminid, customerid, 'all'|'active') return query`: a function to list either _active_ or both _active and expired_ rules
  - `ddps_withdraw_rule(usr, ruleid) return boolean`: a function to withdraw one rule identified by its rule uuid
  - `ddps_addrule(args ....) return boolean`: a function with 20 arguments to add a new rule

They may be tested and used with these commands (first is successful, second shows errors):

## ddps_login(usr,clearpw)

The return value for a successful login is the users uuid and customer uuid. Unsuccessful logins returns nothing. Both failed and successful login attempts are logged in `lastlogin` or `lastfailedlogin`. The number of failed logins are logged to `numberoffailedlogins`.

If a login attempt is made with a valid username but an invalid password  `numberoffailedlogins`  is incremented and the time is logged to `lastfailedlogin`.

If a login attempt is made with a valid username and a valid password but the  `numberoffailedlogins` exceeds 5 then login is only granted if `lastfailedlogin` is more than 1 hour ago to slow down brute force attacks.

`````bash
echo "select public.ddps_login('abnetadm', '1qazxsw2');"|psql -v ON_ERROR_STOP=ON -d flows -t
(6bf8d98b-b217-4a40-9084-7c30f70f44e9,7cae1fea-9cb3-4a8f-898c-625b2a6c81fc)
`````

`````bash
echo "select public.ddps_login('nonexist', '1qazxsw2');"|psql -v ON_ERROR_STOP=ON -d flows -t
# no output
`````

## ddps_listrules(adminid, customerid, 'all'|'active')

List all or only active rules for a specific customer created by a specific user

`````bash
echo "select public.ddps_listrules('6bf8d98b-b217-4a40-9084-7c30f70f44e9', '7cae1fea-9cb3-4a8f-898c-625b2a6c81fc', 'all');"|psql -v ON_ERROR_STOP=ON  -d flows -t

 (1e8afbb4-3856-4655-bf54-afdfae678150,"2020-08-19 13:12:00+02","2020-08-19 13:22:00+02",in,f,t,,"","",,,"",,ælkjækj,10.1.0.0/24,,Expired,discard,"","","","2020-08-19 13:12:53.528247+02")
 (f1b054d7-21eb-408c-b31d-a4e87feb1541,"2020-08-19 13:05:00+02","2020-08-19 13:15:00+02",in,f,t,,"","",,,"",,k,10.0.0. ...
`````

List active rules created by user (is empty)

`````bash
echo "select public.ddps_listrules('6bf8d98b-b217-4a40-9084-7c30f70f44e9', '7cae1fea-9cb3-4a8f-898c-625b2a6c81fc', 'active');"|psql -v ON_ERROR_STOP=ON  -d flows -t
`````

Valid but unknown _uuid_ result in an empty output. Invalid _uuid_ result in an error:

`````bash
ERROR:  invalid input syntax for type uuid: "6bf8d98x-b217-4a40-9084-7c30f70f44e9"
LINE 1: select public.ddps_listrules('6bf8d98x-b217-4a40-9084-7c30f7...
`````

## ddps_withdraw_rule(usr, ruleid)

If the _ruleid_ exists the rule expire time is set to `now()` regardless of what the expire time is (the rule may already have expired). The return status is `TRUE`.

`````bash
echo "select public.ddps_withdraw_rule('6bf8d98b-b217-4a40-9084-7c30f70f44e9', '1e8afbb4-3856-4655-bf54-afdfae678150');"|psql -v ON_ERROR_STOP=ON  -d flows -t
t
`````

If the _ruleid_ does not exist the return status is `FALSE`.

## ddps_addrule(args ....)

The function returns `TRUE` on success and `FALSE` on error(s). The function uses `RAISE EXCEPTION` on the first error.

The function takes the arguments from the table

| #   | Description              | Example                                 |
| --: | -----------------------  | --------------------------------------- |
| 1   | validfrom                | `now()`                                 |
| 2   | validto                  | `now() + '1 min'::interval`             |
| 3   | direction                | `'in'`                                  |
| 4   | srcordestport            | `''`                                    |
| 5   | destinationport          | `'=80'`                                 |
| 6   | sourceport               | `''`                                    |
| 7   | icmptype                 | `''`                                    |
| 8   | icmpcode                 | `''`                                    |
| 9   | packetlength             | `'=1470'`                               |
| 10  | dscp                     | `''`                                    |
| 11  | description              | `'Block port 80'`                       |
| 12  | uuid_customerid          | `'e8f36924-0447-4e8c-bde2-ea9610c01994'`|
| 13  | uuid_administratorid     | `'9800d861-25f4-4d75-a17c-8918a9b3a9bd'`|
| 14  | destinationprefix        | `'10.0.0.1/32'`                         |
| 15  | sourceprefix             | `'0.0.0.0/0'`                           |
| 16  | thenaction               | `'discard'`                             |
| 17  | fragmentencoding         | `''`                                    |
| 18  | ipprotocol               | `'=6'`                                  |
| 19  | tcpflags                 | `''`                                    |

Called as 

`````bash
echo "select public.ddps_addrule(
echo "select public.ddps_addrule(
now(),                      --  1  validfrom...............: now()
now() + '1 min'::interval,  --  2  validto.................: now() + '1 min'::interval
'in',                       --  3  direction...............: 'in'
'',                         --  4  srcordestport...........: ''
'=80',                      --  5  destinationport.........: '=80'
'',                         --  6  sourceport..............: ''
'',                         --  7  icmptype................: ''
'',                         --  8  icmpcode................: ''
'',                         --  9  packetlength............: '=1470'
'=60',                      -- 10  dscp....................: ''
'Block port 80',            -- 11  description.............: 'Block port 80'
'e8f36924-0447-4e8c-bde2-ea9610c01994', -- 12  uuid_customerid.........: 'e8f36924-0447-4e8c-bde2-ea9610c01994'
'9800d861-25f4-4d75-a17c-8918a9b3a9bd', -- 13  uuid_administratorid....: '9800d861-25f4-4d75-a17c-8918a9b3a9bd'
'10.0.0.1/32',              -- 14  destinationprefix.......: '10.0.0.1/32'
'0.0.0.0/0',                -- 15  sourceprefix............: '0.0.0.0/0'
'discard',                  -- 16  thenaction..............: 'discard'
'',                         -- 17  fragmentencoding........: ''
'=6',                       -- 18  ipprotocol..............: '=6'
''                          -- 19  tcpflags................: ''
);"|psql -v ON_ERROR_STOP=ON  -d flows -t
`````
will return the value `TRUE` and insert the new rule in the database.

Calling with i.e. non flowspec compliant values example `dscp =90` (max value is 63) results in an error

`````bash
ERROR:  dscp =90 is not flowspec compliant
CONTEXT:  PL/pgSQL function ddps_addrule(timestamp ...
`````

Some errors may be more generic example setting the _destination port_ to negative 80 results in

`````bash
ERROR:  port-* =-80 is not flowspec compliant
CONTEXT:  PL/pgSQL function ddps_addrule(timestamp with time ...
`````

Notice that on most fields has restrictions to either prevent invalid data entering the database or organisations adding more rules or adding the rules more rapidly than what is acceptable. See the table definitions for more information.

## has_destip_rights(uuid_administratorid, destinationprefix)

Function to test if an administrator may create rule(s) for `destinationprefix`. Returns boolean, used as constraint for table `ddps.flowspecrules`. 

