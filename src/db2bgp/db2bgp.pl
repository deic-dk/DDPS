#!/usr/bin/perl -w
#
# Database to BGP flowspec service (db2bgp)

# Requirements
use strict;
use warnings;
use feature qw(switch);
use sigtrap qw(die normal-signals);		#
use POSIX qw(strftime);					# date format
use POSIX ();
use DBI;								# database
use Net::OpenSSH;

use FindBin ();
use File::Basename ();
use File::Spec::Functions qw(catfile);

use Sys::Syslog;        # only needed for logit
use File::Basename;
use Getopt::Long qw(:config no_ignore_case);

use 5.14.0;								# say, switch etc.
use experimental qw( switch );
use Sys::Syslog;						# logit

use Net::Subnet;
use Net::Netmask;
use Data::Validate::IP;
use Proc::Daemon;

require '/opt/db2bgp/lib/sqlstr.pm';

# global vars
my %data;
my $dsn;
my $dbh;
my $shutdown;
my $lockfile;
my $reload;
my $sleeptime = 2;
my $gobgp;
my $daemontype;
my $gobgphosts;
my $datadir;
my $ini;
my %gobgp_start_time;

my @our_networks;
my @tcpflags;
my %rulestatus;
my @fragment;
my @ip_protocols;
my @thenactions;

my $invalid_rule_msg = "Invalid flowspec";

my $script = File::Basename::basename($0);
my $SELF  = catfile($FindBin::Bin, $script);

my $verbose = 0;
my $daemonize = 0;
my $daemon = 0;
my $test = 0;
my $add = 0;
my $expire = 0;
my $printr = 0;
my $printxp = 0;

#INCLUDE_VERSION_PM
my $show_version = 0;

# sub prototypes
sub ini_read($);
sub exit_usage();
sub connect2db($$$);
sub read_my_netwoks_from_database();
sub read_rule_status_from_database();
sub read_tcpflags_from_database();
sub read_fragment_from_database();
sub read_ip_protocols_from_database();
sub testconnection();
sub logit($@);
sub is_valid_flowspec($$$@);
sub is_subnet_in_net($$);
sub main(@);
sub exclusive_lock();
sub validate_one_rule($@);
sub enforce_rule_and_update_db($$$@);
sub process_new_rules();
sub process_expired_rules();
sub send_rule($$$);
sub update_db($$$$);
sub process_gui_pressed_exire_expired_rules();
sub sshexecgobgp($$$);
sub process_all_active_rules($);
sub sshgobgpuptime($);
sub run_as_daemon();
sub addrule(@);
sub printrules($);
sub expirerule(@);
sub read_uuid_administratorid_and_uuid_customerid_from_database();
sub read_default_sql_dates_from_database($);
sub update_hostinfo();
sub initialize_hostinfo();

################################################################################
# MAIN
################################################################################

main();

exit(0);

#
# Subs
#
sub main(@) {

	# ini file in . or ../etc/
	#my $bindir	= dirname(__FILE__);
	#my $basedir	= dirname($bindir);
	#my $etcdir	= $basedir . "/etc";
	#$ini = "$etcdir" . "/ddps.ini";
	$ini = "/opt/db2bgp/etc//ddps.ini";

	if (!GetOptions(
			'ini|f=s'		=> \$ini,
			'verbose|v'		=> \$verbose,
            'test|t'        => \$test,
			'daemon|d'		=> \$daemon,
			'daemonize|D'	=> \$daemonize,
			'add|a'			=> \$add,
			'print|p'		=> \$printr,
			'log|l'			=> \$printxp,
			'expire|e'		=> \$expire
	))
	{
		exit_usage();
    }

	if ($add) {
		addrule(@ARGV);
	} elsif ($expire) {
		expirerule(@ARGV);
	} elsif ($printxp) {
		printrules("active_and_expired_rules");
	} elsif ($printr) {
		printrules("active_rules");
	} elsif ($daemon || $daemonize) {
		print ("starting daemon ... \n");
		run_as_daemon();
	} else
	{
		# running daemon in foreground
		run_as_daemon();
	}
	exit 0;
}

sub printrules($)
{
	my $rule_scope = $_[0];
	our $q_current_rules;
	our $q_all_rules;

	my $sql = "";

	given ($rule_scope) {
		when ("active_rules") {
			$sql = $q_current_rules;
		}
		when ("active_and_expired_rules") {
			$sql = $q_all_rules;
		}
		default {
			print("undefined: rule_scope = $rule_scope\n");
			exit (127);
		}
	}


	my $oldverbose = $verbose;
	$verbose = 0;
	if(ini_read($ini) != 0) {
		printf("failed to read ini file '%s', bye\n", $ini);
		exit 1;
	}
	if (connect2db("$data{'general'}{'dbname'}", "$data{'general'}{'dbuser'}", "$data{'general'}{'dbpassword'}") != 1)
	{
		printf("error connecting to database, bye\n");
		exit 1;
	}
	my $sth = $dbh->prepare($sql);
	if (! $sth ) {
			logit($verbose, "Couldn't prepare statement: " . $dbh->errstr);
	}
	if (! $sth->execute ) {
		logit($verbose, "Couldn't execute statement: " . $sth->errstr);
	}
	my ($flowspecruleid,$validfrom,$validto,$notification,$thenaction,$description);

	printf("%-38s %-32s %-32s %-14s %-20s %s\n", "Rule UUID", "Valid from", "Valid until", "Status", "Action", "Description");
	print '-' x 160 . "\n";
	my $i = 0;
	while (my @row = $sth->fetchrow_array)
	{
		($flowspecruleid,$validfrom,$validto,$notification,$thenaction,$description) = @row;
		printf("%-38s %-32s %-32s %-14s %-20s %s\n", $flowspecruleid,$validfrom,$validto,$notification,$thenaction,$description);
		$i ++;
	}
	print "read $i rules\n";

	exit 0;
}


sub expirerule(@)
{
	my $expire_rule_uuid = $_[0];

	my $help = "
Expire / remove rule:

	$0 [-v] -e rule-UUID

Rules should be specified as their rule UUID.  See a list of
active rules and their UUID with
	$0 -p

Use the GUI or '$0 -p' to see if the rule has been removed

";

	my $rule_not_found = 0;
	given($expire_rule_uuid) {
		when("help") {
			print $help;
			exit 0;
		}
		when(defined($expire_rule_uuid) && (length($expire_rule_uuid) gt 0)) {
			our $q_expire_one_rule;
			my $oldverbose = $verbose;
			$verbose = 0;
			if(ini_read($ini) != 0) {
				printf("failed to read ini file '%s', bye\n", $ini);
				exit 1;
			}
			if (connect2db("$data{'general'}{'dbname'}", "$data{'general'}{'dbuser'}", "$data{'general'}{'dbpassword'}") != 1)
			{
				printf("error connecting to database, bye\n");
				exit 1;
			}
			$verbose = $oldverbose;

			my $sql_query = $q_expire_one_rule;
			for ($sql_query) {
				s/_remove_rule_uuid_/$expire_rule_uuid/g;
			}
			my $sth = $dbh->prepare($sql_query);
			if (! $sth ) {
					logit($verbose, "Couldn't prepare statement: " . $dbh->errstr);
			}
			if (! $sth->execute ) {
				logit($verbose, "Couldn't execute statement: " . $sth->errstr);
			}
		}
		default {
			print $help;
			exit 0;
		}
	}
	exit 0;
}

sub addrule(@)
{
	my $rule = join(' ' , @_);

	my $rule_not_appliable = 0;

	given($rule) {
		when("help") {
			print<<EOF;
Add rule help

Parameters that have a default value may be omitted and the default will be value used.    
All applied parameters must have the format var: [value], please encapsulate line in single quotes

    validfrom            timestamp with time zone: YYYY-mm-dd HH:MM:SS CET DEFAULT time now
    expireafter          minutes until expire DEFAULT 10 min, lower values not accepted
    direction            in | out DEFAULT in
    destinationport      =80 =443 >=10&<=100 ... range 0-65536 DEFAULT any
    sourceport           =80 =443 >=10&<=100 ... range 0-65536 DEFAULT any
    icmptype             =0 =3 ..                range 0-255 DEFAULT any
    icmpcode             =0 =3 ..                range 0-255 DEFAULT any
    length               =60 =1470 >=10&<=100    range 60-9000 DEFAULT any
    dscp                 =0 ...                  range 0-63 DEFAULT any
    description          Descriptive text
    destinationprefix    One valid CIDR within our constituency NO DEFAULT
    sourceprefix         One valid CIDR within our constituency DEFAULT ANY
    action               accept | discard | rate-limit 9600 | rate-limit 19200 | rate-limit 38400 DEFAULT discard
    fragment             One or more of is-fragment dont-fragment first-fragment last-fragment not-a-fragment DEFAULT any
    tcpflags             One of fin syn rst push ack urgent
    protocol             =0 =3 ...               range 0-255 DEFAULT any

Examples: - lines has been wrapped for readability
    1) Block access to TCP port 22 on 10.0.0.1 next 120 min from 169.254.0.0/16
       $0 -a '
       direction [in] sourceprefix [169.254.0.0/16] destinationprefix [10.0.0.1/32]
       protocol [=6] destinationport [=22] expireafter [120]
       description [block SSH access, newer know who they are] action [discard]'

    2) Block access with UDP fragments to 10.0.0.1 from any next 7 days
       $0 -a '
       direction [in] protocol [=17] destinationprefix [10.0.0.1/32]
       fragment [is-fragment]
       expireafter [604800] description [block some UDP fragments] action [discard]'

EOF
			exit 0;
		}
		#	default {
		#
		#}
	}

	my $oldverbose = $verbose;
	$verbose = 0;
	if(ini_read($ini) != 0) {
		printf("failed to read ini file '%s', bye\n", $ini);
		exit 1;
	}
	if (connect2db("$data{'general'}{'dbname'}", "$data{'general'}{'dbuser'}", "$data{'general'}{'dbpassword'}") != 1)
	{
		printf("error connecting to database, bye\n");
		exit 1;
	}
	read_my_netwoks_from_database();
	read_tcpflags_from_database();
	read_fragment_from_database();
	read_ip_protocols_from_database();
	read_rule_status_from_database();
	read_thenactions_from_database();

	$verbose = $oldverbose;

	logit($verbose, "read config and values from database ... ");
	logit($verbose, "validating rule ... ");

	my $createdon				= "";
	my $validfrom				= "";
	my $validto					= "";
	my $direction				= "";
	my $destinationport			= "";
	my $sourceport				= "";
	my $icmptype				= "";
	my $icmpcode				= "";
	my $packetlength			= "";
	my $dscp					= "";
	my $description				= "";
	my $destinationprefix		= "";
	my $sourceprefix			= "0.0.0.0/0";
	my $thenaction				= "";
	my $fragmentencoding		= "";
	my $ipprotocol				= "";
	my $tcpflags				= "";
	my $expireafter				= 10;
	my $notification			= "Pending";
	my $uuid_customerid			= "";
	my $uuid_administratorid	= "";

	my $sourceapp			= "cli";

	my $rule_failed_checks_status = 0;
	my $err = 0;

	( $err, $uuid_administratorid, $uuid_customerid ) = read_uuid_administratorid_and_uuid_customerid_from_database();

	our $q_add_rule;

	# remove duplicate replaced spaces in $rule
	$rule =~ s/\s+/ /g;
	# split rule: var [value] var [value] ...  in var/value pairs
	for my $word (split(/]/, $rule))
  	{
		my $var;
		my $value;
		($var, $value) = split(/\[/, $word);
		$var =~ s/^\s+|\s+$//g;
		$value =~ s/^\s+|\s+$//g;
		logit($verbose, "var '$var' =  '$value'");

		given(lc $var){
			when ("destinationprefix") {
				$destinationprefix = $value;
				if (! is_valid_flowspec("network", $destinationprefix, '', @our_networks)) {
					logit($verbose, "destination network '$destinationprefix' not part of our networks"); # debug1
					$rule_failed_checks_status += 1;
				}
			}
			when("sourceprefix") {
				$sourceprefix = $value;
				if ($sourceprefix eq '') {
					$sourceprefix = '0.0.0.0/0';
				} else {
					# /^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/igm
					if ( $value !~ m/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/ ) {
						logit($verbose, "source network '$sourceprefix' not CIDR");
						$rule_failed_checks_status += 1;
					}
					my $ip = $sourceprefix;
					$ip =~ s/\/.*$//;
					# follpwing doesn't match correctly: fails on eg 8.8.8.8/32
					# if (is_unroutable_ipv4($ip)|| is_private_ipv4($ip)|| is_loopback_ipv4($ip)|| is_linklocal_ipv4($ip)|| is_testnet_ipv4($ip)|| is_anycast_ipv4($ip)|| \
					# 	is_multicast_ipv4($ip)|| is_loopback_ipv6($ip)|| is_ipv4_mapped_ipv6($ip)|| is_discard_ipv6($ip)|| is_special_ipv6($ip)|| is_teredo_ipv6($ip)|| \
					# 	is_orchid_ipv6($ip)|| is_documentation_ipv6($ip)|| is_private_ipv6($ip)|| is_linklocal_ipv6($ip)|| is_multicast_ipv6($ip)
					#if (is_unroutable_ipv4($ip)|| is_private_ipv4($ip)) {
					#	logit($verbose, "source network '$sourceprefix' not routable or private");
					#	$rule_failed_checks_status += 1;
					#}
				}
			}

			when("protocol") {
				$ipprotocol = $value;
				if ($ipprotocol eq '') {
					$ipprotocol = '';
				} else
				{
					if (! is_valid_flowspec("ipprotocol", '', $ipprotocol, @our_networks))
					{
						logit($verbose, "protocol '$ipprotocol' not flowspec compliant");
						$rule_failed_checks_status += 1;
					} 
				}
			}
			when ("destinationport") {
				$destinationport = $value;
				if (! is_valid_flowspec("port", $destinationport, '', @our_networks))
				{
					logit($verbose, "port '$destinationport' not flowspec compliant");
					$rule_failed_checks_status += 1;
				}
			}
			when ("sourceport") {
				$sourceport = $value;
				if (! is_valid_flowspec("port", $sourceport, '', @our_networks))
				{
					logit($verbose, "port '$sourceport' not flowspec compliant");
					$rule_failed_checks_status += 1;
				}
			}

			when("icmptype") {
				$icmptype = $value;
				if (lc $icmptype ne '') {
					if (! is_valid_flowspec("icmptype", $icmptype, '')) {
						logit($verbose, "icmptype '$icmptype' not valid flowspec");
						$rule_failed_checks_status += 1;
					}
				}
			}
			when("icmpcode") {
				$icmpcode = $value;
				if (lc $icmpcode ne '') {
					if (! is_valid_flowspec("icmpcode", $icmpcode, '')) {
						logit($verbose, "icmpcode '$icmpcode' not valid flowspec");
						$rule_failed_checks_status += 1;
					}
				}
			}
            when("tcpflags") {
				$tcpflags = $value;
				if (! is_valid_flowspec("tcpflags", $tcpflags, '', @our_networks))
				{
					logit($verbose, "tcpflags '$tcpflags' not flowspec compliant");
					$rule_failed_checks_status += 1;
				} 
			}
			when("length") {
				$packetlength = $value;
				if (lc $packetlength ne '') {
					if (! is_valid_flowspec("length", $packetlength, '')) {
						logit($verbose, "length '$packetlength' not valid flowspec");
						$rule_failed_checks_status += 1;
					} 
				}
			}
			when ("dscp") {
				$dscp = $value;
				if (! is_valid_flowspec("dscp", $dscp, '', @our_networks))
				{
					logit($verbose, "dscp '$dscp' not flowspec compliant");
					$rule_failed_checks_status += 1;
				}
			}
			when("fragmentencoding") {
				$fragmentencoding = $value;
				if (! is_valid_flowspec("fragment", $fragmentencoding, '', @our_networks))
				{
					logit($verbose, "fragment '$fragmentencoding' not flowspec compliant");
					$rule_failed_checks_status += 1;
				}
			}

			when ("direction") {
                # 	if ($direction eq '') { $direction = "in";	}
				$direction = $value;
				if (! lc $direction =~ m/^in$|^out$/) {
					logit($verbose, "please specify direction 'in' or 'out', rule rejected");
					$rule_failed_checks_status += 1;
				}
			}
			when("expireafter") {
				$expireafter = $value;
				if ( $expireafter eq '' ) {
					logit($verbose, "empty expireafter not allowed");
					$rule_failed_checks_status += 1;
				} elsif($expireafter =~ /\D/)  {
					logit($verbose, "expireafter may only contain digits");
					$rule_failed_checks_status += 1;
				} elsif ($expireafter < 10) {
					$expireafter = 10;
					logit($verbose, "expireafter must not be lower than 10");
				}
			}
			when("description") {
				$description = $value;
				if ( $description eq '' ) {
					logit($verbose, "empty description not allowed");
					$rule_failed_checks_status += 1;
				}
			}
			when ("action") {
				$thenaction = $value;
				# For now, thenaction should only be limited in GUI and CLI
				foreach my $action ($thenaction)
				{
					my $found = 0;
					foreach my $defined_action ("", @thenactions)
					{
						if (lc $action eq lc $defined_action)
						{
							$found = 1; last;
						}
					}
					if ($found == 0) {
						logit($verbose, "allowed actions: ", join(', ', @thenactions));
						logit($verbose, "cannot implement action field '$action', see help");
						$rule_failed_checks_status += 1;
					}
				}
			}

			default {
				print "parameter error: unknown parameter '$var', value: '$value'\n";
				exit 127;
			}
	    }
  	}

# TODO: is this used?
	if ($destinationprefix eq '') {
		logit($verbose, "empty destinationprefix not allowed");
		$rule_failed_checks_status += 1;
	}
	
	if ($thenaction eq '') {
		logit($verbose, "empty thenaction not allowed");
		$rule_failed_checks_status += 1;
	}
	
	if ($description eq '') {
		logit($verbose, "empty description not allowed");
		$rule_failed_checks_status += 1;
	}
	
	$rule_not_appliable += $rule_failed_checks_status;

	if ($rule_failed_checks_status eq 0) {
		logit($verbose, "rule ok '$rule'");

		($err, $createdon, $validfrom, $validto) = read_default_sql_dates_from_database($expireafter);

		my $sql_query = $q_add_rule;

		for ($sql_query) {
			s/__validfrom__/$validfrom/g;
			s/__validto__/$validto/g;
			s/__direction__/$direction/g;
			s/__isactivated__/false/g;
			s/__isexpired__/false/g;
			s/__srcordestport__//g;
			s/__destinationport__/$destinationport/g;
			s/__sourceport__/$sourceport/g;
			s/__icmptype__/$icmptype/g;
			s/__icmpcode__/$icmpcode/g;
			s/__packetlength__/$packetlength/g;
			s/__dscp__/$dscp/g;
			s/__description__/$description/g;
			s/__uuid_customerid__/$uuid_customerid/g;
			s/__uuid_administratorid__/$uuid_administratorid/g;
			s/__destinationprefix__/$destinationprefix/g;
			s/__sourceprefix__/$sourceprefix/g;
			s/__notification__/$notification/g;
			s/__thenaction__/$thenaction/g;
			s/__fragmentencoding__/$fragmentencoding/g;
			s/__ipprotocol__/$ipprotocol/g;
			s/__tcpflags__/$tcpflags/g;
			s/__sourceapp__/$sourceapp/g;
			s/__createdon__/now()/g;
		}

        if ($test) {
			logit(1, "validfrom: $validfrom");
			logit(1, "validto: $validto");
			logit(1, "direction: $direction");
			logit(1, "isactivated: false");
			logit(1, "isexpired: false");
			logit(1, "srcordestport: ");
			logit(1, "destinationport: $destinationport");
			logit(1, "sourceport: $sourceport");
			logit(1, "icmptype: $icmptype");
			logit(1, "icmpcode: $icmptype");
			logit(1, "packetlength: $packetlength");
			logit(1, "dscp: $dscp");
			logit(1, "description: $description");
			logit(1, "uuid_customerid: $uuid_customerid");
			logit(1, "uuid_administratorid: $uuid_administratorid");
			logit(1, "destinationprefix: $destinationprefix");
			logit(1, "sourceprefix: $sourceprefix");
			logit(1, "notification: $notification");
			logit(1, "thenaction: $thenaction");
			logit(1, "fragmentencoding: $fragmentencoding");
			logit(1, "ipprotocol: $ipprotocol");
			logit(1, "tcpflags: $tcpflags");
			logit(1, "sourceapp: $sourceapp");
			logit(1, "createdon: now()");
            logit(1, "rule ok '$rule'");
			#		logit($verbose, "add rule: sql '$sql_query'");
			logit($verbose, "Test done, rule not enfored or added to database");
            exit 0;
        }
		my $sth = $dbh->prepare($sql_query);
		if (! $sth ) {
				logit($verbose, "Couldn't prepare statement: " . $dbh->errstr);
				$rule_not_appliable = 1;
		}
		if (! $sth->execute ) {
			logit($verbose, "Couldn't execute statement: " . $sth->errstr);
			$rule_not_appliable = 1;
		}

	} else {
        if ($test) {
            logit(1, "invalid rule '$rule'");
            exit 1;
		}
		logit($verbose, "Invalid rule not announced\n");
	}

	$dbh->disconnect();

	given($rule_not_appliable) {
		when(0) { print "ok\n"; exit 0; }
		when(1) { print "fail\n"; exit 1; }
		default { logit($verbose, "program error"); exit 127; }
	}
}

sub initialize_hostinfo()
{
	# Prepare information for the front page
	my $init_sql = "
		DROP TABLE IF EXISTS ddps.hosts;
		CREATE TABLE ddps.hosts (id bigint NOT NULL,hostname character varying);
		DROP TABLE IF EXISTS ddps.hostsinfo;
        CREATE TABLE ddps.hostsinfo (id bigint NOT NULL, status character varying, noofrules bigint, host_id bigint, systemmaintenance timestamp with time zone, description character varying);
        CREATE SEQUENCE ddps.hostsinfo_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
        ALTER SEQUENCE ddps.hostsinfo_id_seq OWNED BY ddps.hostsinfo.id;
        ALTER TABLE ONLY ddps.hostsinfo ALTER COLUMN id SET DEFAULT nextval('ddps.hostsinfo_id_seq'::regclass);
		";
	my $sql_query_tmpl = "
		INSERT INTO ddps.hosts(id, hostname) VALUES (_id_, '_gobgphost_') ON CONFLICT DO NOTHING;
		INSERT INTO ddps.hostsinfo(host_id, status, noofrules, description) VALUES (_id_, 'unknown', 0, '') ON CONFLICT DO NOTHING;
	";

	my $sth = $dbh->prepare($init_sql);
	if (! $sth ) {
			logit($verbose, "Couldn't prepare statement: " . $dbh->errstr);
	}
	if (! $sth->execute ) {
		logit($verbose, "Couldn't execute statement: " . $sth->errstr);
	}
	my $id = 1;

	for my $gobgphost (split(' ', $gobgphosts )) {
		my $sql_query = $sql_query_tmpl;
		for ($sql_query) {
			s/_id_/$id/g;
			s/_gobgphost_/$gobgphost/g;
		}
		my $sth = $dbh->prepare($sql_query);
		if (! $sth ) {
				logit($verbose, "Couldn't prepare statement: " . $dbh->errstr);
		}
		if (! $sth->execute ) {
			logit($verbose, "Couldn't execute statement: " . $sth->errstr);
		}
	$id ++;
	}
}

sub update_hostinfo()
{
	# Update front page information
	logit($verbose, "updating hostinfo .. ");
	# TODO This is executed using ssh on other hosts
	my $show_noofrules = $gobgp . ' global rib -a ipv4-flowspec| awk \'{c+=gsub(/fictitious/,"&")}END{print c}\'';
	logit($verbose, "updating hostinfo:  $show_noofrules");
	my $id = 1;
	for my $gobgphost (split(' ', $gobgphosts )) {

		my $status = "host up";
		my $noofrules = 0;
		my $ssh = Net::OpenSSH->new($gobgphost);
		if ($ssh->error) {
			$status = "host down";
			$noofrules = 0;
		}
		my ($out, $err) = $ssh->capture2("$show_noofrules");
		if ($ssh->error) {
			$status = "remote command failed: " . $ssh->error;
			$noofrules = 0;
		}  else {
			chomp($out);
			$noofrules = $out;
		}
		my $sql_query = "UPDATE ddps.hostsinfo SET status = '$status', noofrules = '$noofrules' WHERE host_id = '$id';";
		# logit($verbose, "DEBUG: sending $sql_query");
		my $sth = $dbh->prepare($sql_query);
		if (! $sth ) {
				logit($verbose, "Couldn't prepare statement: " . $dbh->errstr);
		}
		if (! $sth->execute ) {
			logit($verbose, "Couldn't execute statement: " . $sth->errstr);
		}
		$id ++;
	} 
}

sub run_as_daemon()
{
	if ($daemonize == 1)
	{
		logit($verbose, "daemonizing ...");
		$verbose = 0;
		Proc::Daemon::Init;
		$SIG{TERM} = sub { unlink $lockfile; unlink $shutdown; $dbh->disconnect(); logit($verbose, "cleaned up and terminating, bye"); die "goodbye"; };
		$SIG{HUP}  = sub { unlink $lockfile; unlink $shutdown; $dbh->disconnect(); logit($verbose, "cleaned up and terminating, bye"); die "goodbye"; };
		$SIG{INT}  = sub { unlink $lockfile; unlink $shutdown; $dbh->disconnect(); logit($verbose, "cleaned up and terminating, bye"); die "goodbye"; };
		logit($verbose, "daemonizing done");
	}

	my $return = 0;

	while($return = ini_read($ini) != 0)
	{
		logit($verbose, "error reading ini file, sleeping ${sleeptime} sec ... ");
		sleep(${sleeptime});
	}

	logit($verbose, "database......: ", $data{'general'}{'dbname'});
	logit($verbose, "dbuser........: ", $data{'general'}{'dbuser'});
	logit($verbose, "dbpasswd......: ", $data{'general'}{'dbpassword'});
	logit($verbose, "sleeptime.....: ", $data{'general'}{'sleep_time'});
	logit($verbose, "shutdown......: ", $data{'general'}{'shutdown'});
	logit($verbose, "reload........: ", $data{'general'}{'reload'});
	logit($verbose, "lockfile......: ", $data{'general'}{'lockfile'});
	logit($verbose, "daemontype....: ", $data{'general'}{'daemontype'});
	logit($verbose, "gobgp.........: ", $data{'general'}{'gobgp'});
	logit($verbose, "gobgp hosts...: ", $data{'general'}{'hostlist'});
	logit($verbose, "datadir.......: ", $data{'general'}{'datadir'});

	$sleeptime = $data{'general'}{'sleep_time'};
	$shutdown = $data{'general'}{'shutdown'};
	$lockfile = $data{'general'}{'lockfile'};
	$reload = $data{'general'}{'reload'};
	$gobgp = $data{'general'}{'gobgp'};
	$daemontype = $data{'general'}{'daemontype'};
	$gobgphosts = $data{'general'}{'hostlist'};
	$datadir = $data{'general'}{'datadir'};

	exclusive_lock;

	# If the database is not ready, the ping will catch it, but
	# if the bgp daemon isn't nothing will catch it: rules will
	# not be announced - and will be shown in the GUI as failed
	# which they are. A simple way of mitigation is to postpone
	# the announcements until the system is ready. The simplest
	# way is to sleep until uptime is say 300 seconds,  so this
	# why the following code exists.  The code is Debian/Ubuntu
	# specific, elswhere use Unix::Uptime

	my $minuptime = 300;

	open UPTIME, "</proc/uptime";
	$_ = <UPTIME>;
	chomp;
	my ($uptime , $junk) = split;
	$uptime = int $uptime;

	if (int $uptime <= $minuptime) {
		my $sleeptime = $minuptime - $uptime;
		logit($verbose, "System uptime $uptime sec. too low, sleeping $sleeptime");
		sleep $sleeptime
	} else {
		logit($verbose, "System uptime $uptime sec. ok (exceeds $minuptime sec.)");
	}

	while($return = connect2db("$data{'general'}{'dbname'}", "$data{'general'}{'dbuser'}", "$data{'general'}{'dbpassword'}") != 1)
	{
		logit($verbose, "error connecting to database, sleeping ${sleeptime} sec ... ");
		sleep(${sleeptime});
	}

	# read all network in flow.public.networks
	read_my_netwoks_from_database();
	read_tcpflags_from_database();
	read_fragment_from_database();
	read_ip_protocols_from_database();
	read_rule_status_from_database();
	read_thenactions_from_database();

	my $first_run;
	$first_run = "yes";	# first or later main loop 
	# endless loop
	while(1)
	{
		# check reload signal
		if (-e $reload)
		{
			logit($verbose, "reload from ini and db required ...");
			unlink $reload or logit("failed to remove file $reload ...");
			logit($verbose, "reloading ini file $ini ... ");
			while($return = ini_read($ini) != 0)
			{
				logit($verbose, "error reading ini file, sleeping ${sleeptime} sec ... ");
				sleep(${sleeptime});
			}
			read_my_netwoks_from_database();
			read_tcpflags_from_database();
			read_fragment_from_database();
			read_ip_protocols_from_database();
			read_rule_status_from_database();
			read_thenactions_from_database();
		}
		# check kill signal
		if (-e $shutdown)
		{
			logit($verbose, "shutting down, normal exit");
			unlink $shutdown;
			if (-e $shutdown) {
				logit($verbose, "cannot remove $shutdown!");
			}
			unlink $lockfile;
			$dbh->disconnect();
			exit(0);
		}
		
		# TODO: loop is no longer needed after the check if eabgp has been
		# restated
		given("$first_run") {
			when("no") {
				for my $gobgphost (split(' ', $gobgphosts ))
				{
					if (check_gobgpd_restarted($gobgphost) == 1)
					{
						logit($verbose, "sending all rules to gobgphost '$gobgphost' as it has re-started");
						process_all_active_rules($gobgphost);
					}
					if (-e $datadir . "/" . $gobgphost) {
						logit($verbose, "found semaphore for '$gobgphost': it has re-started");
						process_all_active_rules($gobgphost);
						unlink $datadir . "/" . $gobgphost || logit($verbose, "cannot remove file: $!");
					}
				}
			}
			when("yes") {
				initialize_hostinfo();
				logit($verbose, "fresh start: sending all active rules to gobgp ... ");
				for my $gobgphost (split(' ', $gobgphosts ))
				{
					logit($verbose, "initialising $gobgphost gobgp start time to 0");
					$gobgp_start_time{$gobgphost} = "";  # process uptime unknown
					logit($verbose, "sending all rules to gobgphost '$gobgphost' as this is first time in main loop");
					process_all_active_rules($gobgphost);
				}
				$first_run = "no";
			}
			default {
				logit($verbose, "PROGRAM ERROR: SHOULD NEVER BE HERE: first_run = '$first_run', EXPECTED yes OR no");
			} 
		}
		
		process_new_rules();		# will process all rules/gobgp hosts
		process_expired_rules();	# will process all rules/gobgp hosts
		process_gui_pressed_exire_expired_rules();
									# if  user decide to withdraw an expired rule the state is permanent 'Pending',
									# fix that
		
		update_hostinfo();

		logit($verbose, "safe exit point reached, sleeping ${sleeptime} seconds"); sleep(${sleeptime});
		# loop gobgphosts end
	}
}

# This is the only place we should exit prematurely: to prevent running more than one instance,
# and if we cannot create the lock file due to missing access rights
sub exclusive_lock()
{
	# simple locking to prevent multiple instances run at the same time
	my $timeout = 2;
	$SIG{ALRM} = sub {logit($verbose, "timeout while creating lock, other process running"); die("failed to create lock\n")};
	alarm($timeout);
	use Fcntl qw(:flock);
	open(LOCK, ">>", $lockfile) or die "Error: could not open or create lock: $!";

	logit($verbose, "Waiting for lock...");
	flock(LOCK, LOCK_EX) or die "Error: could not get lock";
	logit($verbose, "lock created");
	alarm(0);
}

sub read_fragment_from_database()
{
	our $q_fragment_names;
	my $i = 0;
	my $sth = $dbh->prepare($q_fragment_names);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$fragment[$i] = join(",", map {$_ ? $_ : "''"} @row);
		$i += 1;
	}
}

sub read_rule_status_from_database()
{
	our $q_rulestatus;
	my $i = 0;
	my $sth = $dbh->prepare($q_rulestatus);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$rulestatus{$row[0]} = $row[1];
		logit($verbose, "reading string array from database: when '$row[0]' print '$rulestatus{$row[0]}'");
	}
}

sub read_default_sql_dates_from_database($)
{
	my $expireafter = $_[0];

	my $i = 0;
	my $err = 0;
	my $createdon	= "";
	my $validfrom	= "";
	my $validto		= "";

	my $q_db_now = "SELECT now()";
	my $q_db_now_plus_interval = "SELECT now() + '$expireafter minutes'::interval;";

	my $sth = $dbh->prepare($q_db_now);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$createdon = join(",", map {$_ ? $_ : "''"} @row);
		$validfrom = join(",", map {$_ ? $_ : "''"} @row);
		$i ++;
	}
	$err += 1 if ($i > 1);

	$sth = $dbh->prepare($q_db_now_plus_interval);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$validto = join(",", map {$_ ? $_ : "''"} @row);
		$i ++;
	}
	$err += 1 if ($i > 1);
	return ($err, $createdon, $validfrom, $validto);

}

sub read_uuid_administratorid_and_uuid_customerid_from_database()
{
	my $uuid_administratorid = "";
	my $uuid_customerid = "";

	my $err = 0;
	# SELECT adminid, customerid FROM ddps.admins WHERe adminroleid = 1 LIMIT 1;
	my $q_administratorid = "select adminid,customerid from ddps.admins where adminroleid = 1 LIMIT 1;";

	my $sth = $dbh->prepare($q_administratorid);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$uuid_administratorid = $row[0];
		$uuid_customerid = $row[1];
	}
	$err += 1 if ($uuid_administratorid eq "");
	$err += 1 if ($uuid_customerid eq "");

	if ($err > 0) {
		logit($verbose, "ERROR: reading either uuid_administratorid or uuid_customerid from the database failed");
	}

	#logit($verbose, "$err, $uuid_administratorid, $uuid_customerid");
	return ($err, $uuid_administratorid, $uuid_customerid);
}

sub read_thenactions_from_database()
{
	our $q_thenactions;
	my $i = 0;
	my $sth = $dbh->prepare($q_thenactions);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$thenactions[$i] = join(",", map {$_ ? $_ : "''"} @row);
		logit($verbose, "reading defined 'then' action(s) from database: $thenactions[$i]");
		$i ++;
	}
}

sub read_tcpflags_from_database()
{
	our $q_tcpflags;
	my $i = 0;
	my $sth = $dbh->prepare($q_tcpflags);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$tcpflags[$i] = join(",", map {$_ ? $_ : "''"} @row);
		$i += 1;
	}
}

sub read_ip_protocols_from_database()
{
	our $q_ip_protocols;
	my $i = 0;
	my $name = "";
	my $sth = $dbh->prepare($q_ip_protocols);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$name = join(",", map {$_ ? $_ : "''"} @row);
		if ($name ne 'other') {
			# read defined names and exclude 'other' used by GUI
			$ip_protocols[$i] = $name;
			logit($verbose, "loading protocol name: $ip_protocols[$i]");
			$i += 1;
		}
	}
	logit($verbose, "loaded $i valid ip protocol names");
}

sub read_my_netwoks_from_database()
{
	our $q_my_netwoks;
	my $i = 0;
	my $sth = $dbh->prepare($q_my_netwoks);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		$our_networks[$i] = join(",", map {$_ ? $_ : "''"} @row);
		$i += 1;
	}
	#for (my $j = 0; $j < $i; $j++) {
	#	#logit($verbose, "valid destination network: $our_networks[$j]");
	#}
	logit($verbose, "loaded $i networks");
}

sub connect2db($$$)
{
	my $dbname	= $_[0];
	my $dbuser	= $_[1];
	my $dbpassword	= $_[2];
	my $host = "127.0.0.1";
	my $port = "5432";

	my $driver  = "Pg";
	logit($verbose, "connecting to $dbname as $dbuser/xxxxxxxx ... ");

	# https://metacpan.org/pod/DBI#AutoCommit, https://metacpan.org/pod/DBI#RaiseError
	# **RaiseError** controls whether the DBI driver generates a Perl error if it
	# encounters a database error. Only set to true if you want to exit in case of errors
	# **AutoCommit** controls whether statements automatically commit their
	# transactions when they complete. Only set AutoCommit to false (0) when bulk
	# loading data to increase database efficiency.
	$dbh = DBI -> connect("dbi:Pg:dbname=$dbname;host=$host;port=$port",
                            $dbuser,
                            $dbpassword,
                            {AutoCommit => 1, RaiseError => 0}
                         ) or return(-1);
	logit($verbose, "AutoCommit: ", $dbh->{AutoCommit});
	logit($verbose, "RaiseError: ", $dbh->{RaiseError});

	given ($dbh->ping) {
		when ($_ == 0) {
			logit($verbose, "database ping: database is idle")
		}
		when ($_ == 1) {
			logit($verbose, "database ping: database is active, there is a command in progress");
		}
		when ($_ == 2) {
			logit($verbose, "database ping: database is idle within a transaction");
		}
		when ($_ == 3) {
			logit($verbose, "database ping: database is idle within a transaction");
		}
		when ($_ == 4) {
			logit($verbose, "database ping: database is idle, within a failed transaction");
		}
	}
	return($dbh->ping);
}

sub testconnection()
{
	given ($dbh->ping) {
		when ($_ == 0) {
			logit($verbose, "database ping: database is idle")
		}
		when ($_ == 1) {
			logit($verbose, "database ping: database is active, there is a command in progress");
		}
		when ($_ == 2) {
			logit($verbose, "database ping: database is idle within a transaction");
		}
		when ($_ == 3) {
			logit($verbose, "database ping: database is idle within a transaction");
		}
		when ($_ == 4) {
			logit($verbose, "database ping: database is idle, within a failed transaction");
		}
	}
	return($dbh->ping);
}

sub process_new_rules()
{
	logit($verbose, "querying for new rules ... ");
	our $q_newrules;
	my $sth = $dbh->prepare($q_newrules);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		if (validate_one_rule("announce", @row) == 0)
		{
			for my $gobgphost (split(' ', $gobgphosts )) {
				enforce_rule_and_update_db($gobgphost, "$daemontype", "announce", @row);
			}
		}
		else
		{
			update_db($row[0], 'FALSE', 'TRUE', $rulestatus{invalid});
			logit($verbose, "rule failed, NOT announcing ...");
		}
	}
}

sub process_expired_rules()
{
	logit($verbose, "querying for expired rules ... ");
	our $q_expired_rules;
	my $sth = $dbh->prepare($q_expired_rules);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		if (validate_one_rule("withdraw", @row) == 0)
		{
			for my $gobgphost (split(' ', $gobgphosts )) {
				enforce_rule_and_update_db($gobgphost, "$daemontype", "withdraw", @row);
			}
		}
		else
		{
			update_db($row[0], 'FALSE', 'TRUE', $invalid_rule_msg);
			logit($verbose, "rule failed, NOT withdraw'ing ...");
		}
	}
}

sub process_gui_pressed_exire_expired_rules()
{
	logit($verbose, "querying for expired rules ... ");
	our $q_fix_gui_press_expire_expired_rule;
	my $sth = $dbh->prepare($q_fix_gui_press_expire_expired_rule);

	if (! $sth->execute()) 
	{
		logit($verbose, "sql failed: ", sth->errstr);
	}
}

sub enforce_rule_and_update_db($$$@)
{
	my $gobgphost = $_[0];
	my $daemontype = $_[1];
	my $type = $_[2];
	shift;
	shift;
	shift;
	my @row = @_;

	# modify statements to keyword [ $value] or ''
	# and replace bare word numbers with =$value
	my $flowspecruleid =			$_[0]  ?  $_[0] : "";
	my $validfrom =					$_[1]  ?  $_[1] : "";
	my $validto =					$_[2]  ?  $_[2] : "";
	my $direction =					$_[3]  ?  $_[3] : "";
	my $isactivated =				$_[4]  ?  $_[4] : "";
	my $isexpired =					$_[5]  ?  $_[5] : "";
	my $srcordestport =				$_[6]  ?  $_[6] : "";
	my $destinationport =			$_[7]  ?  $_[7] : "";
	my $sourceport =				$_[8]  ?  $_[8] : "";
	my $icmptype =					$_[9]  ?  $_[9] : "";
	my $icmpcode =					$_[10] ? $_[10] : "";
	my $packetlength =				$_[11] ? $_[11] : "";
	my $dscp =						$_[12] ? $_[12] : "";
	my $description =				$_[13] ? $_[13] : "";
	my $customerid =				$_[14] ? $_[14] : "";
	my $uuid_customerid =			$_[15] ? $_[15] : "";
	my $uuid_administratorid =		$_[16] ? $_[16] : "";
	my $destinationprefix =			$_[17] ? $_[17] : "";
	my $sourceprefix =				$_[18] ? $_[18] : "";
	my $notification =				$_[19] ? $_[19] : "";
	my $thenaction =				$_[20] ? $_[20] : "discard";
	my $fragmentencoding =			$_[21] ? $_[21] : "";
	my $ipprotocol =				$_[22] ? $_[22] : "";
	my $tcpflags =					$_[23] ? $_[23] : "";
	my $sourceapp =					$_[24] ? $_[24] : "";
	my $uuid_fastnetmoninstanceid =	$_[25] ? $_[25] : "";

	# must be cidr
	if ($sourceprefix =~ m|0\.0\.0\.0/(0*)$| )
	{
		$sourceprefix = '';
	}
	if ($sourceprefix !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| && $sourceprefix ne '')
	{
		$sourceprefix = $sourceprefix . "/32";
	}
	if ($sourceprefix ne '') { $sourceprefix = " source " . $sourceprefix ; }

	# must be cidr too
	if ($destinationprefix !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| && $destinationprefix ne '')
	{
		$destinationprefix = $destinationprefix . "/32";
	}
	# fix missing len destination 10.11.255.1/32;
	if ($destinationprefix ne '') { $destinationprefix = " destination " . $destinationprefix; }

	my $m_ip_proto = "";
	# protocol '=0 =1 =3 =5 =6 =7 ... =255'
	if ($ipprotocol eq '') {
		$m_ip_proto = $ipprotocol ? " protocol '" . $ipprotocol . "'" : "";
	}
	# GUI uses other for setting eg. GRE
	elsif ($ipprotocol eq "other")
	{
		$m_ip_proto = $ipprotocol ? " protocol '" . $ipprotocol . "'" : "";
	}
	else
	# GUI selected protocol icmp, tcp or udp
	{
		# TODO replace
		# icmp with =1
		# tcp with  =6
		# udp with =17
		$m_ip_proto = $ipprotocol ? " protocol '" . $ipprotocol . "'" : "";
	}
	# icmp-type =0 =1 =3 =5 =6 =7 >=10&<=12 >=13&<=15 >=17&<=19 =255;
	# icmp-code =0 =10 =21 =23 =25 =26 =27 >=30&<=32 >=33&<=35 >=37&<=39 =255;
	if ($icmptype ne '') {
		$icmptype = " icmp-type '" . $icmptype . "'"; }
	if ($icmpcode ne '') {
		$icmpcode = " icmp-code '" . $icmpcode . "'"; }

	# TODO
	# Tcp-flags defined in database and elswhere as [fin syn rst push ack urgent]; 
	# But gobgp Supported TCP Flags are:
	# https://github.com/osrg/gobgp/blob/master/docs/sources/flowspec.md#cli-syntax
	# F (=FIN), S (=SYN), R (=RST), P (=PUSH), A (=ACK), U (=URGENT), C (=CWR), E (=ECE)
	# So a rewrite is needed. The cli syntax is 'F S R P A U C E' or '=F =S =R =P ...'
	# as it seems like = is optional. Notice case though
	if ($tcpflags ne '') {
		for ($tcpflags) {
			s/fin/=F/gi;
			s/syn/=S/gi;
			s/rst/=R/gi;
			s/push/=P/gi;
			s/ack/=A/gi;
			s/urgent/=U/gi;
			s/cwr/=C/gi;
			s/ece/=E/gi;
		}
		$tcpflags =~ s/(.*)\1/$1/g;

		$tcpflags = " tcp-flags '" . $tcpflags . "'";
	}
	if ($fragmentencoding ne '') {
		$fragmentencoding = " fragment '" . $fragmentencoding . "'";
	}

	# packet-length =0 =40 =46 =201 =203 =205 =206 =207 >=300&<=302 >=303&<=305 >=307&<=309 =65535;
	if ($packetlength ne '') {
		$packetlength = " packet-length '" . $packetlength . "'";
	}
	 # port =0 =21 =23 =25 =26 =27 >=30&<=32 >=33&<=35 >=37&<=39 =65535;
	if ($destinationport ne '') {
		$destinationport = " destination-port '" . $destinationport . "'";
	}
	if ($sourceport ne '') {
		$sourceport = " source-port '" . $sourceport . "'";
	}
	# dscp =0 =1 =3 =5 =6 =7 >=10&<=12 >=13&<=15 >=17&<=19 =48 =63;
	if ($dscp ne '') {
		$dscp = " dscp '" . $dscp . "'";
	}
	my $ruleid = substr($flowspecruleid, 0, 7);	# just for readability

	# rule = source 0.0.0.0/0 destination 10.0.0.1/32 protocol '=6' source-port '<=65535&>=1024' then discar
	# POLICY = add | del
	# gobgp global rib $POLICY -a ipv4-flowspec match $RULE
	if ($thenaction ne '') {
		$thenaction = "then " . $thenaction;
	} else {
		$thenaction = "then discard";
	}
	my $send_err;
	my $msg;
	my $new_isactivated_status;
	my $new_isexpired_status;
	my $rule = "";

	if ($type eq "announce") {
		$rule = "global rib add -a ipv4-flowspec match ";
		$new_isactivated_status = 'TRUE';
		$new_isexpired_status = 'FALSE';
	}
	elsif ($type eq "withdraw") {
		$rule = "global rib del -a ipv4-flowspec match ";
		$new_isactivated_status = 'FALSE';
		$new_isexpired_status = 'TRUE';
	}
	else
	{
		logit($verbose, "program error, type = $type");
		exit ;
	}
	$rule =  $rule . "$sourceprefix"				.
				"$destinationprefix"		. "$sourceport"		.
				"$destinationport"			. "$m_ip_proto"		.
				"$tcpflags" . "$icmptype"	. "$icmpcode"		.
				"$packetlength"	. "$fragmentencoding" . "$dscp"	.
				" " . "$thenaction";

	$rule =~ s/ +/ /g;

	for my $gobgphost (split(' ', $gobgphosts )) {
		($send_err, $msg) = send_rule("$gobgphost", "$type", "$rule");
		if ($send_err eq 0)
		{
			logit($verbose, "rule sent ok: '$msg'");
			update_db($flowspecruleid,$new_isactivated_status,$new_isexpired_status,$msg);
		}
		else
		{
			logit($verbose, "sending rule failed: '$msg', setting isactivated FALSE and isexpired TRUE to prevent further damage");
			$new_isactivated_status = 'FALSE';
			$new_isexpired_status = 'TRUE';
			$msg = $rulestatus{'failure'};
			update_db($flowspecruleid,$new_isactivated_status,$new_isexpired_status,$msg);
		}
	}
}

sub update_db($$$$)
{
	# TODO
	# When implementing the rule fails, update_db should have an extra field for notifying the database
	# setting notification = 'Failed'
	#
	my ($flowspecruleid, $new_isactivated_status, $new_isexpired_status, $notification_string) = @_;

	our $q_update_rule_activation_and_notification;
	my $sql_query = $q_update_rule_activation_and_notification;
	$sql_query =~ s/\Q%s\E/$flowspecruleid/g;

	#logit($verbose, "update_db: notification_string: '$notification_string'");

	for ($sql_query) {
		s/\Q__FLOWSPECRULEID__\E/$flowspecruleid/g;
		s/__NOTIFICATION__/$notification_string/g;
		s/__NEW_ISEXPIRED_STATUS__/$new_isexpired_status/g;
		s/__NEW_ISACTIVATED_STATUS__/$new_isactivated_status/g;
	}
	my $sth = $dbh->prepare($sql_query);
	if (! $sth->execute()) 
	{
		logit($verbose, "sql failed: ", sth->errstr);
	}
}


sub send_rule($$$)
{
	my $gobgphost = $_[0];
	my $type = $_[1];
	my $rule = $_[2];
	my $msg;
	logit($verbose, "sending rule to host: '$gobgphost', rule: $rule");

	my $lines = 4;
	my $output = "";
	my $err = "";
	my $error_string = "";

	my $cmd = "$rule";

	my $show_status = "$gobgp 'gobgp global rib -a ipv4-flowspec'";						# replaces gobgpcli 'show adj-rib out'
	($err,$error_string, $output) = sshexecgobgp("$gobgphost", "$lines","${cmd}");
	#	exit 0 on success, 1 on error(s) + prints info on stdout.

	$msg = "$rulestatus{'program_error'}";

	if ($type eq "announce") {
		$msg = $rulestatus{'active'}
	}
	if ($type eq "withdraw") {
		$msg = $rulestatus{'expired'}
	}
	if ($output ne "" || $err != 0)
	{
		# we *may have an error* but dont pester the gui yet
		logit($verbose, "Add rule failed rule: '$rule'");
		logit($verbose, "gobgpcli may have encountered an error");
		logit($verbose, "Exit status: '$err'");
		logit($verbose, "Output.....: '$output'");
		logit($verbose, "gobgp global rib -a ipv4-flowspec'");
	}
	return ($err, $msg);
}

sub validate_one_rule($@)
{
	my $type = $_[0];
	shift;
	my @row = @_;

	my $flowspecruleid =			$_[0]  ?  $_[0] : "";
	my $validfrom =					$_[1]  ?  $_[1] : "";
	my $validto =					$_[2]  ?  $_[2] : "";
	my $direction =					$_[3]  ?  $_[3] : "";
	my $isactivated =				$_[4]  ?  $_[4] : "";
	my $isexpired =					$_[5]  ?  $_[5] : "";
	my $srcordestport =				$_[6]  ?  $_[6] : "";
	my $destinationport =			$_[7]  ?  $_[7] : "";
	my $sourceport =				$_[8]  ?  $_[8] : "";
	my $icmptype =					$_[9]  ?  $_[9] : "";
	my $icmpcode =					$_[10] ? $_[10] : "";
	my $packetlength =				$_[11] ? $_[11] : "";
	my $dscp =						$_[12] ? $_[12] : "";
	my $description =				$_[13] ? $_[13] : "";
	my $customerid =				$_[14] ? $_[14] : "";
	my $uuid_customerid =			$_[15] ? $_[15] : "";
	my $uuid_administratorid =		$_[16] ? $_[16] : "";
	my $destinationprefix =			$_[17] ? $_[17] : "";
	my $sourceprefix =				$_[18] ? $_[18] : "";
	my $notification =				$_[19] ? $_[19] : "";
	my $thenaction =				$_[20] ? $_[20] : "discard";
	my $fragmentencoding =			$_[21] ? $_[21] : "";
	my $ipprotocol =				$_[22] ? $_[22] : "";
	my $tcpflags =					$_[23] ? $_[23] : "";
	my $sourceapp =					$_[24] ? $_[24] : "";
	my $uuid_fastnetmoninstanceid =	$_[25] ? $_[25] : "";

    # Destinationprefix data type in postgres is inet, so a.b.c.d/32 is HOST (a.b.c.d) In
    # flowspec we always use CIDR not HOST so assume host when not CIDR.
	# must be cidr
	if ($destinationprefix !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| && $destinationprefix ne '')
	{
		$destinationprefix = $destinationprefix . "/32";
	}

	if ($sourceprefix !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| && $sourceprefix ne '')
	{
		$sourceprefix = $sourceprefix . "/32";
	}

	# check parameters ok
	my $rule_failed_checks_status = 0;	# increment on error
	
    # for now just ignore sourceprefix
    if (! $sourceprefix eq '')
	{
		if (is_valid_flowspec("network", $sourceprefix, '', @our_networks))
		{
			# logit($verbose, "WARN: source network '$sourceprefix' is part of our networks");
			$rule_failed_checks_status += 0;
		}
	}

	if (! is_valid_flowspec("network", $destinationprefix, '', @our_networks))
	{
		logit($verbose, "destination network '$destinationprefix' not part of our networks"); # debug2
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("ipprotocol", '', $ipprotocol, @our_networks))
	{
		logit($verbose, "ipprotocol '$ipprotocol' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("tcpflags", $tcpflags, '', @our_networks))
	{
		logit($verbose, "tcpflags '$tcpflags' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("dscp", $dscp, '', @our_networks))
	{
		logit($verbose, "DSCP '$dscp' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("length", $packetlength, '', @our_networks))
	{
		logit($verbose, "length '$packetlength' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("fragment", $fragmentencoding, '', @our_networks))
	{
		logit($verbose, "fragment '$fragmentencoding' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("port", $destinationport, '', @our_networks))
	{
		logit($verbose, "port '$destinationport' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("port", $srcordestport, '', @our_networks))
	{
		logit($verbose, "port '$srcordestport' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("icmptype", $icmptype, '', @our_networks))
	{
		logit($verbose, "icmptype '$icmptype' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}
	elsif (! is_valid_flowspec("icmpcode", $icmpcode, '', @our_networks))
	{
		logit($verbose, "icmpcode '$sourceport' not flowspec compliant");
		$rule_failed_checks_status += 1;
	}

	# TODO: Try to filter out protocol mismatch, this should go in a separate function where the whole
	# rule should be scrutinised 
	# Order below important: $ipprotocol may be empty
	if ($ipprotocol eq lc 'icmp' || ($ipprotocol ne '' && $ipprotocol =~ m/[=]1$/ ))
	{
			my $tmpstr = $sourceport . $destinationport . $srcordestport;
			if ($tmpstr ne '')
			{
				logit($verbose, "IP package type icmp cannot have port-* fields (dport$destinationport, sport:$sourceport, sordport: $srcordestport)");
				$rule_failed_checks_status += 1;
			}
	}

	# 2)	ipprotocol=tcp,udp then icmp-* not allowed
	# 3)	ipprotocol != 1,6,17,58,136 then   icmp-*, port* not allowed
	# 		protocol = other and not icmp
	#		protocol = other and not udp,tcp
	# 4)	check if $ipprotocol != tcp,udp && port-* == ''
	#		'other' and != tcp, udp, icmp and not '' ... but is difficult, as ipprotocol may be specified as >=0 ...
	#
	#	logit($verbose, "Only IP package type icmp have icmpcode or icmptype fields (icmpcode:$icmpcode, icmptype:$icmptype)");
	#	($ipprotocol != 1 || $ipprotocol != 6 || $ipprotocol != 17 || $ipprotocol != 58 || $ipprotocol != 136))
	return $rule_failed_checks_status;
}

sub ini_read($)
{
	my $ini = $_[0];
	my $section;
	if (open my $fh, '<', $ini)
	{
	
	   while (my $line = <$fh>) {
		   if ($line =~ /^\s*#|^\s*;/) {
			   next;	   # skip comments
		   }
		   if ($line =~ /^\s*$/) {
			   next;	   # skip empty lines
		   }
	
		   if ($line =~ /^\[(.*)\]\s*$/) {
			   $section = $1;
			   next;
		   }
	
		   if ($line =~ /^([^=]+?)\s*=\s*(.*?)\s*$/) {
			   my ($field, $value) = ($1, $2);
			   if (not defined $section) {
				   logit($verbose, "Error in '$ini': Line outside of seciton '$line'");
				   next;
			   }
			   $data{$section}{$field} = $value;
			   #logit("read ${section}[${field}] = $value");
		   }
	   }
	   logit($verbose, "read $ini ok");
	}
	else {
		logit($verbose, "Could not open file '$ini' $!");
		return(-1);
	}
	close($ini);
	return(0);
}

sub exit_usage()
{
			print<<"EOF";

		Usage:
		Run as daemon:
		$0 [-v] [-D] [-f ini-style-config-file]
		-v: verbose, run in foreground
		-f: alternative ini file,
			default ini file $ini

		-a: <args> add rule ..., use 'help' for usage
		-d: run as daemon in foreground
		-D: daemonize log to syslog
		-p: show log of active rules
		-l: show all expired rules
		-e: expire rule uuid ...

		Only first flag honored

EOF
	exit;
}

sub is_valid_flowspec($$$@)
{
	my ($type, $value, $subvalue) = @_;
	$value		=~ s/^\s+|\s+$//g;	# trim value
	$subvalue	=~ s/^\s+|\s+$//g;	# trim value
	shift; shift; shift;
	my @our_assigned_networks = @_;

	# THIS HAS TO GO INTO SOME SPECIFICATION OF THE API
	# Status for full BGP flowspec syntax check 
	# [-]   1 Destination Prefix: may be any IP so ignored
	# [x]   2 Source Prefix: must be assigned to us
	# [x]   3 IP Protocol
	# [x]   4 Source or Destination Port
	# [x]   5 Destination Port
	# [x]   6 Source Port
	# [x]   7 ICMP Type
	# [x]   8 ICMP Code
	# [x]   9 TCP flags
	# [x]  10 Packet length
	# [x]  11 DSCP (may have to be changed as I dont know the syntax yet)
	# [x]  12 Fragment Encoding

	given($type){
		#  1 Destination Prefix, 
		#  2 Source Prefix
		when("network") {
			foreach (@our_assigned_networks)
			{
				if (is_subnet_in_net($value, $_))
				{
					return 1; last;
				}
			}
			return 0;
		}
		#  3 IP Protocol
		when("ipprotocol") {
			#logit(1, "DEBUG: got ipprotocol and '$subvalue' ..");
			#                    type          value  subvalue ...
			# is_valid_flowspec("ipprotocol", '', $ipprotocol, @our_networks)
			my $is_ok = 1;	# assume no errors
			# is it empty then return ok
			if ( $value =~ m/^(?![\s\S])/ && $subvalue =~ m/^(?![\s\S])/ )
			{
				#logit(1, "ipprotocol empty");
				return $is_ok;
			}
			# check if it is a known protocol word and return . Loop in loop raise error if
			# a word in the imput string is unknown. The database should contain this list:
			# egp, gre, icmp, igmp, igp, ipip, ospf, pim, rsvp, sctp, tcp, udp
			{
				my $found = 0;
				my $found_one = 0;	# found at least one match
				foreach my $sub_value_word (split(/ /, $subvalue))
				{
					foreach my $proto ("", @ip_protocols)
					{
						if (lc $sub_value_word eq lc $proto)
						{
							$found = 1;
							$found_one = 1;
							last;
						}
					}
					if ($found == 0)
					{
						$is_ok = 0;		# change to false only when a word doesn't match
					}
				}
				# mix and match not allowed, so if we have found at least one match stop
				# and return status which is flipped to false if something doesn't match
				if ($found_one == 1) {
					#logit(1, "ipprotocol foune_one == 1, failed");
					return($is_ok);
				}
			}
			# Got here the string is not protocol words nor empty so chekc if it is valid
			# flowspec:
			$is_ok = 1;  # assume no errors
			foreach my $sub_value_word (split(/ /, $subvalue))
			{
				# check it matches
				# an optional <> = followed by number
				# if ($sub_value_word !~ m/^([<>]?=)[0-9&]+$/)
				if ($sub_value_word !~ m/^[<>=&0-9]+$/)
				{
					$is_ok = 0;
					#logit(1, "debug: failed word: '$sub_value_word' no ned to continue ...");
					return($is_ok);	# no need to continue
				}
				# check number is within range 0-255
				for my $vv (split(/ /, $sub_value_word)) {
					 foreach my $v (split(/&/, $vv)) {
						$v =~ s/\=//;
						$v =~ s/\>//;
						$v =~ s/\<//;
						if (int($v) <= 0 && int($v) >= 256)
						{
							$is_ok = 0;
							#logit(1, "ipprotocol '$v' out of range");
							return($is_ok);	# no need to continue
						}
					}
				}
			}
			#logit(1, "debug ipprotocol done, ok = $is_ok");
			return($is_ok);
		}

		#  4 Source or Destination Port
		#  5 Destination Port
		#  6 Source Port
		#    - port 0 and 65535 are both valid,
		#    - see https://www.sans.org/reading-room/whitepapers/auditing/port-scanning-techniques-defense-70
		#	7 ICMP Type
		#	8 ICMP Code
		when(m/port/i||m/icmp/i||/icmpcode/i||/icmptype/i) {
			# value is empty:
			if ( $value eq '' ) { return 1; }
			if ( $value =~ m/^(?![\s\S])/ ) { return 1; }
			if ( $value eq 'NULL') { return 0; } # this is a program / data error: should be '' not string NULL
			my $is_ok = 1;	# assume no errors
			foreach my $word (split(/ /, $value)) {
				foreach my $element (split(/&/, $word)) {
					if ($element !~ m/(?:[<>]?[=]?[0-9]+)/) {
						logit($verbose, "element $element not flowspec comliant");
						$is_ok = 0;
					} else {
						my $p = $element;
						if (($p =~ s/</</g) > 1) {
							logit($verbose, "$type $element ($p) has too meny < signs and is not flowspec comliant");
							return(0);
						}	
						if (($p =~ s/=/=/g) > 1) {
							logit($verbose, "$type $element ($p) has too meny = signs and is not flowspec comliant");
							return(0);
						}
						if (($p =~ s/>/>/g) > 1) {
							logit($verbose, "$type $element ($p) has too meny > signs and is not flowspec comliant");
							return(0);
						}
						$p =~ s/[<>=]?//g;
						if ($p =~ m/\D/) {
							logit($verbose, "$type $element ($p) has non digits and is not flowspec comliant");
							return(0);
						}
						given(lc $type){
							when(m/icmpcode/i||/icmptype/i) {
								if (int($p) < 0 || int($p) > 256) {
									logit($verbose, "icmp-* value $element ($p) out of scope and not flowspec comliant");
									$is_ok = 0;
								}
							}
							when("port") {
								if (int($p) < 0 || int($p) > 65535) {
									logit($verbose, "element $element ($p) out of scope and not flowspec comliant");
									$is_ok = 0;
								}
							}
						}
					}
				}
			}
			return($is_ok);
		}
		#  9 TCP flags
		# TODO
		when("tcpflags") {
			if ( $value =~ m/^(?![\s\S])/ ) { return 1; }	# empty just return

			#my $num_words = 0;
			#++$num_words while $value  =~ /\S+/g;
			#if ($num_words != 1) {
			#	logit($verbose, "expected one word, found '$value'");
			#	return(0);
			#}
			
			my $is_ok = 1;	# assume no errors
			foreach my $tcpval (split(/ /, $value))
			{
				my $found = 0;
				foreach my $flag ("", @tcpflags)
				{
					if (lc $tcpval eq lc $flag)
					{
						$found = 1; last;
					}
				}
				if ($found == 0) {
					logit($verbose, "non flowspec found in tcpflag field '$tcpval'");
					return(0);
				}
			}
			return(1);
		}

		# 10 Packet length
		when("length") {
			# Empty or GUI value
			if ( $value =~ m/^(?![\s\S])/ ) { return 1; }
			if ( $value =~ /^\d+$/ ) {
				if (int($value) >= 48 && int($value) <= 9000) {
					logit($verbose, "packet length must be between 48 and 9000");
					return 1;
				}
			}
			# ethernet frames values are 64 to 9000 bytes. The smallest IP frame is 48 byte but will be padded to 64
			# which is the smallest ethernet frame. Fastnetmon on the other hand, may detect attacks it as low as 60
			# bytes, so any value between 0 and 9000 is ok. 9000 are jumbo frames btw
			# More complex things:
			# packet-length =0 =40 =46 =201 =203 =205 =206 =207 >=300&<=302 >=303&<=305 >=307&<=309 =65535;
			my $is_ok = 1;	# assume no errors
			foreach my $word (split(/ /, $value)) {
				foreach my $len (split(/&/, $word)) {
					if ($len !~ /(?:[<>]?[=]?[0-9]+)/) {
						logit($verbose, "length '$len' not flowspec comliant");
						$is_ok = 0;
					} else {
						my $l = $len;
						$l =~ s/\D+//g;
						if (int($l) < 48 || int($l) > 9000) {
							logit($verbose, "length $len ($l) out of scope and not flowspec comliant, must be between 48 and 9000");
							$is_ok = 0;
						}
					}
				}
			}
			return($is_ok);
		}
		# 11 DSCP (may have to be changed as I dont know the syntax yet)
		# DSCP is a 6 bit field, so it can be represented by decimal 0 to 63
		when("dscp") {
			# Must be as:
			# '' || 0 || =0 =1 =3 =5 =6 =7 >=10&<=12 >=13&<=15 >=17&<=19 =48 =63;
			if ( $value =~ m/^(?![\s\S])/ ) { return 1; }	# empty
			my $d = $value;
			$d =~ s/\D+//g;
			if (int($d) < 0 && int($d) > 63) {
				logit($verbose, "DSCP $d out of scope");
				return 0;
			} else {
				return 1;
			}
			my $is_ok = 1;	# assume no errors
			foreach my $word (split(/ /, $value)) {
				foreach my $dscp (split(/&/, $word)) {
					if ($dscp !~ /(?:[<>]?[=][0-9]+)/) {
						logit($verbose, "DSCP $dscp not flowspec comliant");
						$is_ok = 0;
					} else {
						my $d = $dscp;
						$d =~ s/\D+//g;
						if (int($d) < 0 || int($d) > 63) {
							logit($verbose, "DSCP $dscp ($d) out of scope and not flowspec comliant");
							$is_ok = 0;
						}
					}
				}
			}
			return($is_ok);

		}
		# https://www.cisco.com/c/en/us/td/docs/switches/datacenter/nexus1000/sw/4_0_4_s_v_1_3/qos/configuration/guide/n1000v_qos/n1000v_qos_6dscpval.html
		# 12 Fragment Encoding
		# only one word allowed
		# ++$num_words while $text =~ /\S+/g;
		when("fragment") {
			if ( $value =~ m/^(?![\s\S])/ ) { return 1; }	# empty just return
			my $is_ok = 1;	# assume no errors
			my $num_words = 0;
			my $fragval;
			# is valid: [ is-fragment dont-fragment first-fragment last-fragment not-a-fragment ]
			# so disable one word test
			#++$num_words while $value  =~ /\S+/g;
			#if ($num_words != 1) {
			#	logit($verbose, "expected one word, found '$value'");
			#	return(0);
			#}
			foreach my $fragval (split(/ /, $value))
			{
				my $found = 0;
				foreach my $frag ("", @fragment)
				{
					if (lc $fragval eq lc $frag)
					{
						$found = 1; last;
					}
				}
				if ($found == 0) {
					logit($verbose, "non flowspec found in fragment field '$fragval'");
					return(0);
				}
			}
			return(1);
		}
		default { logit($verbose,"in sub is_valid_flowspec: $type: not yet implemented"); }
	}
}

sub logit($@)
{
	my $verbose = $_[0];
	shift;
	my $msg = join(' ', @_);
	syslog("user|err", "$msg");
	my $now = strftime "%H:%M:%S (%Y/%m/%d)", localtime(time);

	print STDOUT "$now: $msg\n" if ($verbose);
}

sub is_subnet_in_net($$)		# is subnet part of (our) network? true : false
{
	# Check if subnet a.b.d.c/e is a valid subnet of net f.g.h.i/j by replacing
	# netmask of a.b.d.c/ with netmask of f.g.h.i, re-calculate the correct net
	# work of then f.g.h.i and compare it with a.b.d.c
	# And don't accept '' as valid in our case
	# 
	my $subnet = $_[0];
	my $net = $_[1];

	# empty subnet not allowed, and ipaddress not allowed, must be with length
	if ($subnet !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| && $subnet ne '') {
		logit($verbose, "net '$subnet' empty or not CIDR");
		return 0;
	}

	my $netblock = Net::Netmask->new2( $net );
	if (! defined $netblock) {
		logit($verbose, "not a network: ", $Net::Netmask::error);;
		return 0; 
	}
	my $subnetblock = Net::Netmask->new2( $subnet );
	if(! defined $subnetblock) {
		logit($verbose, "not a network: ", $Net::Netmask::error);;
		return 0; 
	}

	my $testnet = $subnetblock->base . "/" . $netblock->bits;
	my $testnetblock = Net::Netmask->new2( $testnet ) or return 0; #warn $Net::Netmask::error;

	my $str1 = sprintf("%s", $testnetblock->base);
	my $str2 = sprintf("%s", $netblock->base);

	if ( lc $str1 eq lc $str2 )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub sshgobgpuptime($)
{
	my $gobgphost = $_[0];
	my $ssh = "ssh ";
	my $str = "";
	# get start time of gobgp process as a text string, if it changes then do something
	# as new processes do not start earlier than old ones
	# TODO FIX BELOW
	my $cmd = '/bin/ps --noheader -o lstart -C gobgpd|awk \'$NF = "/etc/gobgp/gobgp.conf" { $NF=""; print $0; exit }\'';
	# Here be dragons: careful with quotes, the "" escapes on the remote side, so does ''
	open (PIPE, "$ssh $gobgphost $cmd 2>&1 |") || warn "cannot fork: $!";
	my $j = 1;
	while (<PIPE>) {
		$str = $str . $_ if ($j <= 10);
		$j ++;
	}
	close (PIPE);

	my $rc = 0xffff & $?;
	my $error = sprintf "%#04x: ", 0xffff & $?;
	if ($rc == 0) {
		$error .= "with normal exit";
	} elsif ($rc == 0xff00) {
		$error .= "command failled $!";
	} elsif ($rc > 0x90) {
		$rc >>= 8;
		$error .= "ran with non-zero exit status $rc";
	} else {
		$error .= "ran with ";
		if ($rc & 0x80) {
			$rc &= ~0x80;
			$error .= "core dump from ";
		}
		$error .= "signal $rc\n";
	}
	return($rc,$error,$str);
}

sub sshexecgobgp($$$)
{
	# TODO
	# This should use Net::OpenSSH for better error handling
	# 
	my $gobgphost = $_[0];
	my $i = $_[1];
	shift;
	shift;
	my $cmd = join(' ', $_[0]);
	my $str = "";
	my $j = 1;
	my $ssh = "ssh ";
	# Here be dragons: careful with quotes, the "" escapes on the remote side, so does ''
	open (PIPE, "$ssh $gobgphost $gobgp \"$cmd\" 2>&1 |") || warn "cannot fork: $!";
	while (<PIPE>) {
		$str = $str . $_ if ($j <= $i);
		$j ++;
	}
	close (PIPE);

	my $rc = 0xffff & $?;
	my $error = sprintf "%#04x: ", 0xffff & $?;
	if ($rc == 0) {
		$error .= "with normal exit";
	} elsif ($rc == 0xff00) {
		$error .= "command failled $!";
	} elsif ($rc > 0x90) {
		$rc >>= 8;
		$error .= "ran with non-zero exit status $rc";
	} else {
		$error .= "ran with ";
		if ($rc & 0x80) {
			$rc &= ~0x80;
			$error .= "core dump from ";
		}
		$error .= "signal $rc\n";
	}
	return($rc,$error,$str);
}

sub check_gobgpd_restarted($)
{
	my $gobgphost = $_[0];
	# return 1 if gobgp is re-started else 0

	my $err = 0;
	my $error_string = "";
	my $output = "";
	my $lines = 1;
	($err,$error_string, $output) = sshgobgpuptime($gobgphost);
	chomp $output;
	if ("$output" eq "$gobgp_start_time{$gobgphost}") {
		#logit($verbose, "DEBUG: '$output' eq '$gobgp_start_time{$gobgphost}' - gobgp NOT restarted");
		return(0);
	}
	else
	{
		# if output is empty, gobgp is not running at all
        $gobgp_start_time{$gobgphost} = $output if ($output ne '');
		return(1);
	}
}

sub process_all_active_rules($)
{
	my $gobgphost = $_[0];
	logit($verbose, "sending all active rules to $gobgphost ... ");
	our $q_active_rules;
	my $sth = $dbh->prepare($q_active_rules);
	$sth->execute();
	while (my @row = $sth->fetchrow_array)
	{
		# select new, not activated rules only
		if (validate_one_rule("announce", @row) == 0)
		{
			enforce_rule_and_update_db($gobgphost, "$daemontype", "announce", @row);
		}
		else
		{
			logit($verbose, "rule failed, NOT announcing ...");
		}
	}
}



1;

exit 0;

__DATA__

#
#  Modified BSD License
#  ====================
#  
#  Copyright © 2019, Niels Thomas Haugård
#  All rights reserved.
#  
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#  
#  1. Redistributions of source code must retain the above copyright
#	  notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#	  notice, this list of conditions and the following disclaimer in the
#	  documentation and/or other materials provided with the distribution.
#  3. Neither the name of the organisation	DEiC/i2.dk nor the
#	  names of its contributors may be used to endorse or promote products
#	  derived from this software without specific prior written permission.
#  
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL NIELS THOMAS HAUGÅRD BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++
# NAME
#	template.pl 1
# SUMMARY
#	Short description
# PACKAGE
#	file archive exercicer
# SYNOPSIS
#	template.pl options
# DESCRIPTION
#	\fItemplate.pl\fR is used for ...
#	Bla bla.
#	More bla bla.
# OPTIONS
# .IP o
#	I'm a bullet.
# .IP o
#	So am I.
# COMMANDS
#	
# SEE ALSO
#	
# DIAGNOSTICS
#	Whatever.
# BUGS
#	Probably. Please report them to the call-desk or the author.
# VERSION
#	  See git log for version history.
# HISTORY
#	$Log$
# AUTHOR(S)
#	Niels Thomas Haugård
# .br
#	E-mail: thomas@haugaard.net
# .br
#	UNI-C
# .br
#	DTU, Building 305
# .br
#	DK-2800 Kgs. Lyngby
# .br
#	Denmark
#--
