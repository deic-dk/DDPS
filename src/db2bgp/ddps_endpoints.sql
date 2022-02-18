--
-- service db2bgp stop
--
-- Terminate other connections with
--
-- SELECT pg_terminate_backend(pg_stat_activity.pid)
-- FROM pg_stat_activity
-- WHERE pg_stat_activity.datname = 'flows'
--   AND pid <> pg_backend_pid();
-- SELECT pg_terminate_backend(pid)
-- FROM pg_stat_activity
-- WHERE datname = 'flows';
-- 
-- echo 'psql -v ON_ERROR_STOP=ON  -d flows -f ./ddps_endpoints.sql'| su - postgres
--
-- Restart everything
-- service db2bgp start

-- Changes to ddps.admins to mitigate brute force
ALTER TABLE ONLY ddps.admins ADD COLUMN IF NOT EXISTS numberoffailedlogins INT DEFAULT 0;

-- Changes to ddps.customers to enable fair share of firewall router ressources
ALTER TABLE ONLY ddps.customers ALTER COLUMN max_active_rules SET DEFAULT 512;
ALTER TABLE ONLY ddps.customers ALTER COLUMN max_rule_fluctuation_time_window SET DEFAULT 512;

-- Default limitations according to https://www.itoro.com.pl / Kraków 1-2.10.2018 r (pdf)
-- CISCO – Maxium 3000 rules
--   ASR 1xxx
--   ASR 9xxx
--   CSR 1000v
--   CRS-3 (Taiko) LC, CRS-X (Topaz) LC NCS 5500/6000
--   XRv 9000
-- Juniper – Maximum 8000 rules
--   MX series
--   PTX 10002
--   QFX 1000[2/8/16] SRX
--   max-flow may be changed i Junos, see
--   https://www.juniper.net/documentation/en_US/junos/topics/reference/configuration-statement/max-flows-edit-services.html

-- For testing rules, changes to ddps.customers to useless low values
-- ALTER TABLE ONLY ddps.customers ALTER COLUMN max_active_rules SET DEFAULT 2;
-- ALTER TABLE ONLY ddps.customers ALTER COLUMN max_rule_fluctuation_time_window SET DEFAULT 2;

--
-- ddps_addrule(args ....)
--
CREATE OR REPLACE FUNCTION public.ddps_addrule (
--	flowspecruleid uuid,
    validfrom timestamp with time zone,
	validto timestamp with time zone,
    direction character varying(3),
--  isactivated boolean,
--  isexpired boolean,
    srcordestport character varying(128),
    destinationport character varying(128),
    sourceport character varying(128),
    icmptype character varying(128),
    icmpcode character varying(128),
    packetlength character varying(128),
    dscp character varying(128),
    description character varying(256),
--  customerid integer,
    uuid_customerid uuid,
    uuid_administratorid uuid,
    destinationprefix inet,
    sourceprefix inet,
--  notification character varying,
    thenaction character varying,
    fragmentencoding character varying(128),
    ipprotocol character varying(128),
    tcpflags character varying(128)
--  sourceapp character varying,
--  uuid_fastnetmoninstanceid uuid,
--  createdon timestamp with time zone
) RETURNS BOOLEAN
AS $$
DECLARE
    VAR record;
	VALUE character varying(256);
	i integer;
BEGIN
	-- RAISE NOTICE 'validfrom: ''%''
	-- validto: ''%''
	-- direction: ''%''
	-- srcordestport: ''%''
	-- destinationport: ''%''
	-- sourceport: ''%''
	-- icmptype: ''%''
	-- icmpcode: ''%''
	-- packetlength: ''%''
	-- dscp: ''%''
	-- description: ''%''
	-- uuid_customerid: ''%''
	-- uuid_administratorid: ''%''
	-- destinationprefix: ''%''
	-- sourceprefix: ''%''
	-- thenaction: ''%''
	-- fragmentencoding: ''%''
	-- fragmentencoding: ''%''
	-- tcpflags: ''%''
	-- ', validfrom, validto, direction, srcordestport, destinationport, sourceport, icmptype, icmpcode, packetlength, dscp, description, uuid_customerid, uuid_administratorid, destinationprefix, sourceprefix, thenaction, fragmentencoding, ipprotocol, tcpflags ;

	IF TRUE IN
		(SELECT TRUE
			FROM
				ddps.admins
			WHERE
				(ddps.admins.adminid = uuid_administratorid)
				AND (ddps.admins.customerid = uuid_customerid)
				AND (ddps.admins.adminroleid = '1' OR ddps.admins.adminroleid = '3')
			)
			THEN
				-- RAISE NOTICE 'ok';
			ELSE
				RAISE EXCEPTION 'Mismatch between uuid_administratorid, uuid_customerid and admin role';
				RETURN (FALSE);
	END IF;

	-- validfrom, validto, sourceprefix and *uuid* will be caught by function input syntax check (ERROR: ...)
	IF NOT public.is_date(validfrom::varchar) THEN
	 	RAISE EXCEPTION 'Invalid date %', validfrom;
	 	RETURN FALSE;
	END IF;
	IF (direction <> LOWER('in') AND direction <> LOWER('out')) THEN
		RAISE EXCEPTION 'Direction must be in or out, is %', direction;
		RETURN FALSE;
	END IF;
	FOREACH VALUE IN ARRAY ARRAY[srcordestport, destinationport, sourceport]
	LOOP
		IF (public.is_flowspec_type(0, 65535, VALUE) <> 'ok') THEN
			RAISE EXCEPTION 'port-* % is not flowspec compliant', VALUE;
			RETURN FALSE;
		END IF;
	END LOOP;
	FOREACH VALUE IN ARRAY ARRAY[icmptype, icmpcode]
	LOOP
		IF (public.is_flowspec_type(0, 255, VALUE) <> 'ok') THEN
			RAISE EXCEPTION 'icmp-* % is not flowspec compliant', VALUE;
			RETURN FALSE;
		END IF;
	END LOOP;
	IF (public.is_flowspec_type(60, 9000, packetlength) <> 'ok') THEN
		RAISE EXCEPTION 'packetlength % is not flowspec compliant', packetlength;
		RETURN FALSE;
	END IF;
	IF (public.is_flowspec_type(0, 63, dscp) <> 'ok') THEN
		RAISE EXCEPTION 'dscp % is not flowspec compliant', dscp;
		RETURN FALSE;
	END IF;
	IF (description = '') THEN
		RAISE EXCEPTION 'Empty description not allowed';
		RETURN FALSE;
	END IF;
	IF (public.has_destip_rights(uuid_administratorid, destinationprefix) = FALSE) THEN
		RAISE EXCEPTION 'Administrator % has no rights to create rules for % or supernets', uuid_administratorid, destinationprefix;
		RETURN FALSE;
	END IF;
	IF (public.is_thenaction(thenaction) = FALSE) THEN
		RAISE EXCEPTION 'Then action % unknown or not supported', thenaction;
		RETURN FALSE;
	END IF;
	IF (public.is_fragment(fragmentencoding) = FALSE) THEN
		RAISE EXCEPTION 'fragmentencoding % is not flowspec compliant', fragmentencoding;
		RETURN FALSE;
	END IF;
	IF (public.is_tcpflags(tcpflags) = FALSE) THEN
		RAISE EXCEPTION 'tcpflags % are not flowspec compliant', tcpflags;
		RETURN FALSE;
	END IF;

	WITH ROWS as (
	INSERT into ddps.flowspecrules
	(
		flowspecruleid,
		validfrom,
		validto,
		direction,
		isactivated,
		isexpired,
		srcordestport,
		destinationport,
		sourceport,
		icmptype,
		icmpcode,
		packetlength,
		dscp,
		description,
		uuid_customerid,
		uuid_administratorid,
		destinationprefix,
		sourceprefix,
		notification,
		thenaction,
		fragmentencoding,
		ipprotocol,
		tcpflags,
		sourceapp,
		uuid_fastnetmoninstanceid,
		createdon
	)
	values
	(
		gen_random_uuid(),
		validfrom,
		validto,
		direction,
		FALSE,
		FALSE,
		srcordestport,
		destinationport,
		sourceport,
		icmptype,
		icmpcode,
		packetlength,
		dscp,
		description,
		uuid_customerid,
		uuid_administratorid,
		destinationprefix,
		sourceprefix,
		'Pending',
		thenaction,
		fragmentencoding,
		ipprotocol,
		tcpflags,
		'API',
		NULL,
		now()
    )
    RETURNING *
    )
	SELECT COUNT(*) INTO i FROM ROWS;
	RETURN i = 1;

END;
$$ LANGUAGE 'plpgsql';

-- Check ddps.customers.max_active_rules < 500 and 
-- ddps.customers.max_rule_fluctuation_time_window < 500
-- ??

-- ALTER FUNCTION public.ddps_addrule (
-- ) OWNER TO postgres;

--
-- Prevent number of rules exceeds the router(s) capacity
--
CREATE OR REPLACE FUNCTION max_new_flowspecrules_rate_action()
    RETURNS TRIGGER AS $$
BEGIN
    IF
        (
            SELECT count(*)
            FROM
                ddps.flowspecrules
                -- ddps.customers
            WHERE
                -- JOIN kunde
                -- ddps.customers.customerid = new.uuid_customerid
                -- Relevant kunde
                -- AND
                ddps.flowspecrules.uuid_customerid = new.uuid_customerid
                -- Relevant periode
                AND
                ddps.flowspecrules.createdon >= now() - interval '1 minute'
        )
        >
        (
            SELECT ddps.customers.max_rule_fluctuation_time_window
            FROM ddps.customers
            WHERE ddps.customers.customerid = new.uuid_customerid
        )
    THEN
        RAISE EXCEPTION 'Customer specific rules per unit of time exceeded';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS max_new_flowspecrules_rate ON ddps.flowspecrules RESTRICT;

--
-- This may requre truncating the flowspecrules table
--
DROP INDEX ddps.idx_flowspecrules;
CREATE UNIQUE INDEX idx_flowspecrules ON ddps.flowspecrules (
	coalesce (direction, ''),
    coalesce (srcordestport, ''),
	coalesce (destinationport, ''),
	coalesce (sourceport, ''),
	coalesce (icmptype,  ''),
	coalesce (icmpcode, ''),
	coalesce (packetlength, ''),
	coalesce (dscp, ''),
	coalesce (description, ''),
	coalesce (customerid, -1),
	coalesce (uuid_customerid,  'ffffffff-ffff-ffff-ffff-ffffffffffff'),		-- assume not exist
	coalesce (uuid_administratorid, 'ffffffff-ffff-ffff-ffff-ffffffffffff'),	-- assume not exist
	coalesce (destinationprefix, '255.255.255.255/32'),							-- assume invalid
	coalesce (sourceprefix, '255.255.255.255/32'),								-- assume invalid
	coalesce (thenaction, ''),
	coalesce (fragmentencoding, ''),
	coalesce (ipprotocol, ''),
	coalesce (tcpflags, '')
) WHERE not isexpired;

CREATE CONSTRAINT TRIGGER max_new_flowspecrules_rate
AFTER INSERT
ON ddps.flowspecrules
FOR EACH ROW
EXECUTE PROCEDURE max_new_flowspecrules_rate_action();
 
CREATE OR REPLACE FUNCTION max_active_rules_action()
    RETURNS TRIGGER AS $$
BEGIN
    IF
        (
            SELECT count(*)
            FROM
                ddps.flowspecrules
                -- ddps.customers
            WHERE
                -- JOIN kunde
                -- ddps.customers.customerid = new.uuid_customerid
                -- Relevant kunde
                -- AND
                ddps.flowspecrules.uuid_customerid = new.uuid_customerid
                -- Relevant periode
                AND
                (
                    ddps.flowspecrules.isactivated OR
                    ddps.flowspecrules.notification = 'Pending'
                )
          		AND NOT ddps.flowspecrules.isexpired
        )
        >
        (
            SELECT ddps.customers.max_active_rules
            FROM ddps.customers
            WHERE ddps.customers.customerid = new.uuid_customerid
        )
    THEN
        RAISE EXCEPTION 'Customer specific active rules exceeded';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS max_active_rules ON ddps.flowspecrules RESTRICT;

CREATE CONSTRAINT TRIGGER max_active_rules
AFTER INSERT
ON ddps.flowspecrules
FOR EACH ROW
EXECUTE PROCEDURE max_active_rules_action();
 -- XXXXXXXX

--
-- ddps_withdraw_rule(usr, ruleid) return boolean
--
CREATE OR REPLACE FUNCTION public.ddps_withdraw_rule (
	admin_uuid uuid,
	ruleid uuid
) RETURNS BOOLEAN
AS $$
DECLARE
	EXPIRED TEXT;
	i integer;
BEGIN
	SELECT rule_status_value INTO EXPIRED
		rule_status_value 
	FROM
		ddps.rule_status
	WHERE
		rule_status_var = 'expired';
	-- check admin has rights to expire rule
	WITH ROWS as (
    UPDATE ddps.flowspecrules
    SET
        isactivated = FALSE,
        isexpired = TRUE,
        notification = EXPIRED
    WHERE
        ddps.flowspecrules.flowspecruleid = ruleid
        AND (
                EXISTS(
                    SELECT *
                    FROM ddps.flowspecrules AS f, ddps.networks AS n, ddps.accessrights AS a
                    WHERE
                        f.flowspecruleid = ruleid
                        AND
                        f.destinationprefix <<= n.net
                        AND
                        a.network_id = n.networkid
                        AND
                        a.rights = TRUE
                        AND
                        a.admin_id = 	admin_uuid
                )
                OR
                EXISTS(
                    SELECT *
                    FROM ddps.admins
                    WHERE
                        ddps.admins.adminid = admin_uuid
                        AND
                        ddps.admins.adminroleid = 1
                )
        )
    RETURNING *
    )
    SELECT COUNT(*) INTO i FROM ROWS;
    RETURN i = 1;
END;
$$ LANGUAGE 'plpgsql';

ALTER FUNCTION public.ddps_withdraw_rule (
	admin_uuid uuid,
	ruleid uuid
) OWNER TO postgres;

--
-- ddps_listrules
--
CREATE OR REPLACE FUNCTION public.ddps_listrules (
	admin_uuid uuid,
	customer_uuid uuid,
	rule_flag character varying -- ACTIVE | ALL
)
RETURNS TABLE (
	out_flowspecruleid uuid,
	out_validfrom timestamp with time zone,
	out_validto timestamp with time zone,
	out_direction character varying(3),
	out_isactivated boolean,
	out_isexpired boolean,
	out_srcordestport character varying(128),
	out_destinationport character varying(128),
	out_sourceport character varying(128),
	out_icmptype character varying(128),
	out_icmpcode character varying(128),
	out_packetlength character varying(128),
	out_dscp character varying(128),
	out_description character varying(256),
	-- customerid integer,
	-- uuid_customerid uuid,
	-- uuid_administratorid uuid,
	out_destinationprefix inet,
	out_sourceprefix inet,
	out_notification character varying,
	out_thenaction character varying,
	out_fragmentencoding character varying(128),
	out_ipprotocol character varying(128),
	out_tcpflags character varying(128),
	-- sourceapp character varying,
	-- uuid_fastnetmoninstanceid uuid,
	out_createdon timestamp with time zone
) AS $$
BEGIN
	RETURN QUERY
	SELECT
		ddps.flowspecrules.flowspecruleid,
		ddps.flowspecrules.validfrom,
		ddps.flowspecrules.validto,
		ddps.flowspecrules.direction,
		ddps.flowspecrules.isactivated,
		ddps.flowspecrules.isexpired,
		ddps.flowspecrules.srcordestport,
		ddps.flowspecrules.destinationport,
		ddps.flowspecrules.sourceport,
		ddps.flowspecrules.icmptype,
		ddps.flowspecrules.icmpcode,
		ddps.flowspecrules.packetlength,
		ddps.flowspecrules.dscp,
		ddps.flowspecrules.description,
		-- ddps.flowspecrules.customerid,
		-- ddps.flowspecrules.uuid_customerid,
		-- ddps.flowspecrules.uuid_administratorid,
		ddps.flowspecrules.destinationprefix,
		ddps.flowspecrules.sourceprefix,
		ddps.flowspecrules.notification,
		ddps.flowspecrules.thenaction,
		ddps.flowspecrules.fragmentencoding,
		ddps.flowspecrules.ipprotocol,
		ddps.flowspecrules.tcpflags,
		-- ddps.flowspecrules.sourceapp,
		-- ddps.flowspecrules.uuid_fastnetmoninstanceid,
		ddps.flowspecrules.createdon
	FROM 
		ddps.flowspecrules
	WHERE
		ddps.flowspecrules.uuid_customerid = customer_uuid
		AND
		ddps.flowspecrules.uuid_administratorid = admin_uuid
		AND
        CASE
            WHEN UPPER(rule_flag) = 'ACTIVE'
				AND ddps.flowspecrules.isactivated
				AND NOT ddps.flowspecrules.isexpired
            THEN TRUE
            WHEN UPPER(rule_flag) = 'ALL'
            THEN TRUE
            ELSE
                FALSE
        END 
    ;
    RETURN;
END;
$$ LANGUAGE 'plpgsql';

ALTER FUNCTION public.ddps_listrules (
	admin_uuid uuid,
	customer_uuid uuid,
	word character varying
) OWNER TO postgres;

-- SELECT public.ddps_listrules('6bf8d98b-b217-4a40-9084-7c30f70f44e9', '7cae1fea-9cb3-4a8f-898c-625b2a6c81fc', 'active');
-- select public.ddps_listrules('7cae1fea-9cb3-4a8f-898c-625b2a6c81fc','6bf8d98b-b217-4a40-9084-7c30f70f44e9', 'all');


--
-- ddps_login
--
CREATE OR REPLACE FUNCTION public.ddps_login(usr character varying, pw character varying) RETURNS TABLE(adminid uuid, customerid uuid)
    LANGUAGE plpgsql
    AS $$
BEGIN
        IF TRUE IN
                (SELECT TRUE
                        FROM ddps.admins
                        WHERE
                            ddps.admins.username = usr
                            AND ddps.admins.password = crypt(pw, password)
                            AND ddps.admins.status = TRUE
                            AND (
                                numberoffailedlogins < 2
                                OR (
                                    numberoffailedlogins >= 2
                                    AND
                                    lastfailedlogin < now() - INTERVAL '2 MINUTES'
                                )
                            )
                 )
        THEN
            UPDATE ddps.admins
            SET
                lastlogin = now(),
                numberoffailedlogins = 0
            WHERE
                ddps.admins.username = usr		-- Evt. custumerid + username skal være UNIQUE istedet
                AND ddps.admins.password = crypt(pw, password);
               
            RETURN QUERY
                SELECT
                    ddps.admins.adminid,
                    ddps.admins.customerid
                FROM
                    ddps.admins
                WHERE
                    ddps.admins.username = usr	-- Evt. custumerid + username skal være UNIQUE istedet
                    AND ddps.admins.password = crypt(pw, password);
        ELSE
            UPDATE ddps.admins
            SET
                lastfailedlogin = now(),
                numberoffailedlogins = numberoffailedlogins + 1
            WHERE
                ddps.admins.username = usr;
          -- cannot RAISE and do an update (nulls transaction), see
            -- https://stackoverflow.com/questions/55406735/can-a-postgres-commit-exist-in-procedure-that-has-an-exception-block
            -- RAISE EXCEPTION 'No such user ''%'' or wrong password', usr;
        END IF;
END;
$$;


ALTER FUNCTION public.ddps_login(usr character varying, pw character varying) OWNER TO postgres;

-- ALTER TABLE ddps.admins ADD COLUMN IF NOT EXISTS lastfailedlogin timestamp with time zone;
-- CREATE OR REPLACE FUNCTION public.ddps_login (
--     usr character varying,
--     pw  character varying
-- ) RETURNS TABLE (adminid uuid, customerid uuid) AS $$
-- BEGIN
--         IF TRUE IN
--                 (SELECT TRUE
--                         FROM ddps.admins
--                         WHERE
--                             ddps.admins.username = usr
--                             AND ddps.admins.password = crypt(pw, password)
--                             AND ddps.admins.status = TRUE
--                             AND (
--                                 numberoffailedlogins < 5
--                                 OR (
--                                     numberoffailedlogins >= 5
--                                     AND
--                                     lastfailedlogin < now() - INTERVAL '60 MINUTES'
--                                 )
--                             )
--                  )
--         THEN
--             UPDATE ddps.admins
--             SET
--                 lastlogin = now(),
--                 numberoffailedlogins = 0
--             WHERE
--                 ddps.admins.username = usr		-- Evt. custumerid + username skal være UNIQUE istedet
--                 AND ddps.admins.password = crypt(pw, password); 
--                
--             RETURN QUERY
--                 SELECT
--                     ddps.admins.adminid,
--                     ddps.admins.customerid
--                 FROM
--                     ddps.admins
--                 WHERE
--                     ddps.admins.username = usr	-- Evt. custumerid + username skal være UNIQUE istedet
--                     AND ddps.admins.password = crypt(pw, password);
--         ELSE
--             UPDATE ddps.admins
--             SET
--                 lastfailedlogin = now(),
--                 numberoffailedlogins = numberoffailedlogins + 1
--             WHERE
--                 ddps.admins.username = usr                 -- Evt. custumerid + username skal være UNIQUE istedet
--                 AND ddps.admins.password = crypt(pw, password);
--           -- cannot RAISE and do an update (nulls transaction), see
--             -- https://stackoverflow.com/questions/55406735/can-a-postgres-commit-exist-in-procedure-that-has-an-exception-block
--             -- RAISE EXCEPTION 'No such user ''%'' or wrong password', usr;
--         END IF;
-- END;
-- $$ LANGUAGE 'plpgsql';
-- 

ALTER FUNCTION public.ddps_login(
	usr character varying,
	pw  character varying
) OWNER TO postgres;

-- test(s)
-- select * from ddps.admins where ddps.admins.username = 'abnetadm';
-- select public.ddps_login('abnetadm', '$2a$10$hvKylD3EDR2b810ZvX81GudhchmLAJ7Y5/YdVNIjFY8EEi7xuk6AC');
-- select public.ddps_login('abnetadm', '1qazxsw2');
-- select * from ddps.admins where ddps.admins.username = 'abnetadm';

-- |Flowspec type                       | Function                    |Applied|Status
-- |Type  1 - Destination Prefix        | has_destip_rights           |[X]    |OK
-- |Type  2 - Source Prefix             | we have only inbound rules  |       |
-- |Type  3 - IP Protocol               | is_flowspec_type            |[X]    |Ok
-- |Type  4 – Source or Destination Port| is_flowspec_type            |[X]    |Ok
-- |Type  5 – Destination Port          | is_flowspec_type            |[X]    |Ok
-- |Type  6 - Source Port               | is_flowspec_type            |[X]    |Ok
-- |Type  7 – ICMP Type                 | is_flowspec_type            |[X]    |Ok
-- |Type  8 – ICMP Code                 | is_flowspec_type            |[X]    |Ok
-- |Type  9 - TCP flags                 | is_tcpflags                 |[X]    |OK
-- |Type 10 - Packet length             | is_flowspec_type            |[X]    |Ok
-- |Type 11 – DSCP                      | is_flowspec_type            |[X]    |Ok
-- |Type 12 - Fragment Encoding         | is_fragment                 |[X]    |Ok
-- #################################################################################

-- Honor GoBGP limitations on flowspec length
ALTER TABLE ddps.flowspecrules ALTER COLUMN fragmentencoding TYPE character varying(128);
ALTER TABLE ddps.flowspecrules ALTER COLUMN ipprotocol TYPE character varying(128);
ALTER TABLE ddps.flowspecrules ALTER COLUMN tcpflags TYPE character varying(128);

CREATE OR REPLACE LANGUAGE plperl;

ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_srcordestport;
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_destinationport;
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_sourceport;
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_icmptype;
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_icmpcode;
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_packetlength;
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_dscp;
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_flowspec_type_protocol;

-- Function to test flowspec expressions with values within given range
-- E.g. range 0-255 and >=10&<=100 ....
DROP FUNCTION IF EXISTS public.is_flowspec_type(INT, INT, character varying);
CREATE FUNCTION public.is_flowspec_type(lower integer, upper integer, bgp_string character varying) RETURNS character varying AS $$
    my ($lower, $upper, $bgp_string) = @_;

	return "argument too long"	if (length($bgp_string) > 128);
    return "missing lower boundary"	if not defined $lower;
    return "missing upper boundary"	if not defined $upper;

    if ($bgp_string =~ m/^[0-9]+$/) { return "ok"; }

	foreach my $sub_value_word (split(/ /, $bgp_string)) {
		if ($sub_value_word !~ m/^[<>=&0-9]+$/) {
			return "not flowspec: '$bgp_string' contains illegal chars or multiple spaces";
		}
		for my $var (split(/&/, $sub_value_word)) {
			if ($var =~ m/^[0-9]+$/ ) {
				return "not flowspec: '$var' must be prepended with an '=' sign";
			}
			my $p = $var;
			if ($p =~ m/=</) {
				return "not flowspec: '$var' =<";
			}
			if ($p =~ m/=>/) {
				return "not flowspec: '$var' =>";
			}
			if ($p =~ m/==/) {
				return "not flowspec: '$var' ==";
			}

			if (($p =~ s/>/>/g) > 1) {
				return "not flowspec: '$var' has too many > signs";
			}
			if (($p =~ s/=/=/g) > 1) {
				return "not flowspec: '$var' has too many = signs";
			}
			if (($p =~ s/</</g) > 1) {
				return "not flowspec: '$var' has too many < signs";
			}

			# check boundaries
			$var =~ s/\=|\<|\>//g;
			if ($var < $lower) {
				return "not flowspec: $var below boundary $lower";
			}
			if ($var > $upper) {
				return "not flowspec, $var above boundary $upper";
			}
		}
	}
	return "ok";
$$ LANGUAGE plperl;

ALTER FUNCTION public.is_flowspec_type(lower integer, upper integer, bgp_string character varying) OWNER TO postgres;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_srcordestport CHECK (public.is_flowspec_type(0, 65535, srcordestport) = 'ok') NOT VALID;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_destinationport CHECK (public.is_flowspec_type(0, 65535, destinationport) = 'ok') NOT VALID;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_sourceport CHECK (public.is_flowspec_type(0, 65535, sourceport) = 'ok') NOT VALID;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_icmptype CHECK (public.is_flowspec_type(0, 255, icmptype) = 'ok') NOT VALID;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_icmpcode CHECK (public.is_flowspec_type(0, 255, icmpcode) = 'ok') NOT VALID;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_packetlength CHECK (public.is_flowspec_type(60,9000, packetlength) = 'ok') NOT VALID;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_dscp CHECK (public.is_flowspec_type(0, 63, dscp) = 'ok') NOT VALID;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_flowspec_type_protocol CHECK (public.is_flowspec_type(0, 255, ipprotocol) = 'ok') NOT VALID;

-- Then actions are stored in the database, just check values comply
-- E.g. accept, discard, rate-limit 9600, rate-limit 19200 or rate-limit 38400
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_valid_thenaction;
CREATE OR REPLACE FUNCTION public.is_thenaction (thenaction_string character varying) RETURNS BOOLEAN AS $$
DECLARE
    i INTEGER := 1 ;
BEGIN
    LOOP
        --IF (SPLIT_PART(thenaction_string,' ',i) <> '') THEN
            IF (LOWER(thenaction_string) not in (select LOWER(thenvalue) from ddps.thenaction )) THEN
                RETURN(false) ;
            ELSE
                i := i+1 ;
            END IF ;
        --ELSE
            RETURN(TRUE) ;
        --END IF;
    END LOOP ;
END ;
$$ LANGUAGE 'plpgsql';
ALTER FUNCTION public.is_thenaction(thenaction_string character varying) OWNER TO postgres;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_valid_thenaction CHECK (public.is_thenaction(thenaction) = TRUE) NOT VALID;

-- TCP flags are stored in the database, just check all values comply e.g. fin syn ack but not foo
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_valid_tcpflags;
DROP FUNCTION IF EXISTS public.is_tcpflags(character varying);
CREATE FUNCTION public.is_tcpflags (tcpflags_string character varying) RETURNS BOOLEAN AS $$
DECLARE
    i INTEGER := 1 ;
BEGIN
    LOOP
        IF (SPLIT_PART(tcpflags_string,' ',i) <> '') THEN
            IF (LOWER( SPLIT_PART(tcpflags_string,' ',i)) not in (select LOWER(tcpflagvalue) from ddps.tcpflags )) THEN
                RETURN(false) ;
            ELSE
                i := i+1 ;
            END IF ;
        ELSE
            RETURN(TRUE) ;
        END IF;
    END LOOP ;
END ;
$$ LANGUAGE 'plpgsql';
ALTER FUNCTION public.is_tcpflags(tcpflags_string character varying) OWNER TO postgres;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_valid_tcpflags CHECK (public.is_tcpflags(tcpflags) = TRUE) NOT VALID;

-- Fragment names are stored in the database, check all word(s) matches database words e.g. is-fragment last-fragment but not foo
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS is_valid_fragment;
DROP FUNCTION IF EXISTS public.is_fragment(character varying);
CREATE FUNCTION public.is_fragment (fragment_string character varying) RETURNS BOOLEAN AS $$
DECLARE
    i INTEGER := 1 ;
BEGIN
    LOOP
        IF (SPLIT_PART(fragment_string,' ',i) <> '') THEN
            IF (LOWER( SPLIT_PART(fragment_string,' ',i)) not in (select LOWER(fragvalue) from ddps.fragment )) THEN
                RETURN(false) ;
            ELSE
                i := i+1 ;
            END IF ;
        ELSE
            RETURN(TRUE) ;
        END IF;
    END LOOP ;
END ;
$$ LANGUAGE 'plpgsql';

ALTER FUNCTION public.is_fragment(fragment_string character varying) OWNER TO postgres;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT is_valid_fragment CHECK (public.is_fragment(fragmentencoding) = TRUE) NOT VALID;

-- Check 'administratorid' may create rule for 'destinationprefix', where 'destinationprefix' may be a subnet of a defined network.
-- Allways allow adminroleid '1' to create rules
ALTER TABLE ddps.flowspecrules DROP CONSTRAINT IF EXISTS admin_owns_destip;
DROP FUNCTION IF EXISTS public.has_destip_rights(uuid, inet);
CREATE FUNCTION public.has_destip_rights (administratorid uuid, destinationprefix inet) RETURNS BOOLEAN AS $$
BEGIN
IF TRUE IN
        (SELECT TRUE
        FROM ddps.admins, ddps.networks
        WHERE
            ddps.admins.adminroleid = '1'
            AND ddps.admins.adminid = administratorid
            AND destinationprefix <<= ddps.networks.net
            -- and network actually exists
            )
        THEN
            RETURN (TRUE);
	 ELSE
   if true in (SELECT TRUE
	 FROM ddps.admins, ddps.networks
	 WHERE
	 		ddps.admins.adminroleid = '2'
	 		AND ddps.admins.adminid = administratorid
      AND destinationprefix <<= ddps.networks.net
      AND ddps.admins.customerid = ddps.networks.uuid_networkcustomerid
          )
      THEN
          RETURN (TRUE);
    ELSE
        IF TRUE IN
            (SELECT TRUE
            FROM ddps.accessrights, ddps.networks
            WHERE ddps.accessrights.network_id = ddps.networks.networkid
                    AND ddps.accessrights.admin_id = administratorid
                    AND ddps.accessrights.rights = TRUE
                    AND destinationprefix <<= ddps.networks.net )
            THEN
                RETURN (TRUE);
            ELSE
                RETURN (FALSE);
        END IF;
		ELSE
			RETURN (FALSE);
     END IF;
END IF;
END
$$ LANGUAGE 'plpgsql';
ALTER FUNCTION public.has_destip_rights(administratorid uuid, destinationprefix inet) OWNER TO postgres;
ALTER TABLE ddps.flowspecrules ADD CONSTRAINT admin_owns_destip CHECK (public.has_destip_rights(uuid_administratorid, destinationprefix) = TRUE) NOT VALID;

-- From https://stackoverflow.com/questions/25374707/check-whether-string-is-a-date-postgresql
CREATE OR REPLACE FUNCTION public.is_date(s varchar) RETURNS BOOLEAN AS $$
BEGIN
  perform s::date;
  RETURN TRUE;
EXCEPTION WHEN others THEN
  RETURN FALSE;
eND;
$$ LANGUAGE 'plpgsql';

---
--- Prevent dangeling rules, where networks are deleted while rule(s) are active
---
CREATE OR REPLACE FUNCTION BlockingRulesWhenModifyingNetworks() RETURNS trigger AS $$
    BEGIN
        if (TG_OP = 'DELETE') THEN
 
            if TRUE IN
            (
                select TRUE
                from ddps.flowspecrules
                where
                    not isexpired
                    and
                    destinationprefix <<= OLD.net
            ) THEN
                RAISE EXCEPTION 'Dette netværk kan ikke slettes pga. non-expired regel';
            END IF;
            RETURN OLD;
        END IF;    
        IF (TG_OP = 'UPDATE') THEN
 
            if TRUE IN
            (
                select TRUE
                from ddps.flowspecrules
                where
                    not isexpired
                    and
                    destinationprefix <<= OLD.net
                    and NOT destinationprefix <<= NEW.net
            ) THEN
                RAISE EXCEPTION 'Dette netværk kan ikke ændres pga. non-expired regel' ;
            END IF;
 
            RETURN NEW;
 
        END IF;
 
    END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS BlockingRulesWhenModifyingNetworks ON ddps.networks RESTRICT;

CREATE TRIGGER BlockingRulesWhenModifyingNetworks
BEFORE DELETE OR UPDATE
ON ddps.networks
FOR EACH ROW
EXECUTE PROCEDURE BlockingRulesWhenModifyingNetworks();


-- Modified BSD License
-- ====================
-- 
-- Copyright © 2020, Niels Thomas Haugård and Frank Thingholm 
-- www.deic.dk, wwww.i2.dk.dk
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Neither the name of the organisation  www.deic.dk, wwww.i2.dk.dk nor the
--    names of its contributors may be used to endorse or promote products
--    derived from this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL NIELS THOMAS HAUGÅRD BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
