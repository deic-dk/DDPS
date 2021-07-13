# 
# sql strings as global vars
#

# query for combind set of our networks. We must only create rules
# for cidr's within these networks
$q_my_netwoks = << 'EOF';
SELECT distinct net
FROM
   ddps.networks
  ;
EOF

# query for new rules
$q_newrules = <<'EOF';
SELECT distinct
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
	customerid,
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
	uuid_fastnetmoninstanceid
FROM
   ddps.flowspecrules
WHERE
	not isexpired
	AND not isactivated
ORDER BY
	validto DESC,
	flowspecruleid, validfrom, validto, direction, isactivated, isexpired, srcordestport,
	destinationport, sourceport, icmptype, icmpcode, packetlength, dscp, description,
	customerid, uuid_customerid, uuid_administratorid, destinationprefix,
	sourceprefix, notification, thenaction, fragmentencoding, ipprotocol, tcpflags,
	sourceapp, uuid_fastnetmoninstanceid;
EOF


$q_tcpflags = <<'EOF';
SELECT distinct
    tcpflagvalue
FROM
   ddps.tcpflags
;
EOF

$q_ip_protocols = <<'EOF';
SELECT distinct
    protocolvalue
FROM
   ddps.protocols
;
EOF


$q_fragment_names = <<'EOF';
SELECT distinct
    fragvalue
FROM
   ddps.fragment
;
EOF

$q_update_rule_activation_and_notification = << 'EOF';
UPDATE ddps.flowspecrules
	set
		isactivated = __NEW_ISACTIVATED_STATUS__,
		isexpired = __NEW_ISEXPIRED_STATUS__,
		notification = '__NOTIFICATION__'
	where flowspecruleid in ( '__FLOWSPECRULEID__' );
;
EOF


$q_expired_rules = <<'EOF';
SELECT distinct
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
	customerid,
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
	uuid_fastnetmoninstanceid
FROM
    ddps.flowspecrules
WHERE
    isactivated
    AND not isexpired
    AND now() >= validto order by validto DESC;
EOF

;

# query for all activated rules
$q_active_rules = <<'EOF';
SELECT distinct
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
	customerid,
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
	uuid_fastnetmoninstanceid
FROM
   ddps.flowspecrules
WHERE
	not isexpired
ORDER BY
	validto DESC,
	flowspecruleid, validfrom, validto, direction, isactivated, isexpired, srcordestport,
	destinationport, sourceport, icmptype, icmpcode, packetlength, dscp, description,
	customerid, uuid_customerid, uuid_administratorid, destinationprefix,
	sourceprefix, notification, thenaction, fragmentencoding, ipprotocol, tcpflags,
	sourceapp, uuid_fastnetmoninstanceid;
EOF


# query for all activated rules
$q_rulestatus = <<'EOF';
SELECT
	rule_status_var,
	rule_status_value
FROM
	ddps.rule_status;
EOF

# $check_admin_rights_on_dst = << 'EOF';	-> q_admin_may_create_rule_for_destination
# end

# Pre-defined action(s)
#
$q_thenactions = << 'EOF';
select
	thenvalue
from
	ddps.thenaction;
EOF

# Add rule
$q_add_rule = << 'EOF';
insert into ddps.flowspecrules
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
		'__validfrom__',
		'__validto__',
		'__direction__',
		'__isactivated__',
		'__isexpired__',
		'__srcordestport__',
		'__destinationport__',
		'__sourceport__',
		'__icmptype__',
		'__icmpcode__',
		'__packetlength__',
		'__dscp__',
		'__description__',
		'__uuid_customerid__',
		'__uuid_administratorid__',
		'__destinationprefix__',
		'__sourceprefix__',
		'__notification__',
		'__thenaction__',
		'__fragmentencoding__',
		'__ipprotocol__',
		'__tcpflags__',
		'__sourceapp__',
		NULL,
		'__createdon__'
	);
EOF

$q_current_rules = << 'EOF';
SELECT distinct
	flowspecruleid,validfrom,validto,notification,thenaction,description
FROM
	ddps.flowspecrules
WHERE
	isactivated
ORDER BY
	validfrom,validto DESC;
	
EOF

$q_all_rules = << 'EOF';
SELECT distinct
	flowspecruleid,validfrom,validto,notification,thenaction,description
FROM
	ddps.flowspecrules
ORDER BY
	validfrom,validto DESC;
	
EOF


$q_expire_one_rule = << 'EOF';
UPDATE
	ddps.flowspecrules
SET
	validto=now()
WHERE
	flowspecruleid in ( '_remove_rule_uuid_' );
EOF

$q_fix_gui_press_expire_expired_rule = << 'EOF';
UPDATE
	ddps.flowspecrules
SET notification = 'Expired'
WHERE
	notification in ('Pending') and isexpired;
EOF

1;
