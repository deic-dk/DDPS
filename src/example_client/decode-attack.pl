#!/usr/bin/perl -w
#
# apt install build-essential; cpan Path::Tiny
#
# - read tcpdump from stdin; fastnetmon has at least two different tcpdump formats
# - write processed tcpdump as csv
# - read csv, calculate lowest common denominator for each field
# - print rulefile

# prototypes
sub main(@);
sub logit(@);
sub mydie(@);
sub parse_ip($);
#sub parse_ip6($);
sub parse_v4(@);
sub randstr(@);
sub min($$);
sub max($$);

# Requirements
use strict;
use warnings;
use 5.14.0;             # say, switch etc.
use File::Temp qw(tempfile);
use File::stat;
use Getopt::Long qw(:config no_ignore_case);
use IO::Socket::INET;
use POSIX;              # only needed for logit
use Path::Tiny;
use Socket qw( inet_aton );
use Sys::Hostname;
use Sys::Syslog;        # only needed for logit
use sigtrap qw(die normal-signals);

# Global vars
my $usage = "\n$0	client_ip_as_string data_direction pps action\n";
my $tmpcsvdir = "/tmp/";
# tcpdump
my ($date, $time, $src_sport, $andgt, $dst_dport, $protocol, $frag, $packets, $length, $icmp_type, $icmp_code, $flags, $str, $ttl, $ratio, $dscp);
my ($src, $sport, $dst, $dport, $ver, $ip, $port);
# fastnetmon specific
my (
	$attack_type, $Initial_attack_power, $Peak_attack_power, $attack_protocol,
	$Total_incoming_traffic, $Attack_direction, $Total_outgoing_traffic,
	$Total_incoming_pps, $Total_outgoing_pps, $Total_incoming_flows,
	$Total_outgoing_flows, $Average_incoming_traffic, $Average_outgoing_traffic,
	$Average_incoming_pps, $Average_outgoing_pps, $Average_incoming_flows,
	$Average_outgoing_flows, $Incoming_ip_fragmented_traffic,
	$Outgoing_ip_fragmented_traffic, $Incoming_ip_fragmented_pps,
	$Outgoing_ip_fragmented_pps, $Incoming_tcp_traffic, $Outgoing_tcp_traffic,
	$Incoming_tcp_pps, $Outgoing_tcp_pps, $Incoming_syn_tcp_traffic,
	$Outgoing_syn_tcp_traffic, $Incoming_syn_tcp_pps, $Outgoing_syn_tcp_pps,
	$Incoming_udp_traffic, $Outgoing_udp_traffic, $Incoming_udp_pps,
	$Outgoing_udp_pps, $Incoming_icmp_traffic, $Outgoing_icmp_traffic,
	$Incoming_icmp_pps, $Outgoing_icmp_pps, $Network_incoming_traffic,
	$Network_outgoing_traffic, $Network_incoming_pps, $Network_outgoing_pps,
	$Average_network_incoming_traffic, $Average_network_outgoing_traffic,
	$Average_network_incoming_pps, $Average_network_outgoing_pps,
	$Average_packet_size_for_incoming_traffic,
	$Average_packet_size_for_outgoing_traffic
	);
$attack_type = "";
my $verbose = 0;

my $logfile = "/tmp/" . "logfile.txt";
my $inicfg	= "./fnm2db.ini";

################################################################################
# MAIN
################################################################################

main();

exit(0);

#
# Subs
#
sub main(@) {

	if(defined $ARGV[0]){
		if($ARGV[0] eq "-v")
		{
				$verbose = 1;
				shift @ARGV;
		}
	} else {
			print("usage: $usage\n");
			exit 0;
	}

	my $client_ip_as_string	=	$ARGV[0];	# ipv4 address
	my $data_direction		=	$ARGV[1];	# 10.0.0.1 other 0 attack_details
	my $pps					=	$ARGV[2];	# number
	my $action				=	$ARGV[3];	# ban | unban | attack_details
	my $error_string		= "";

	logit ("start: $0 @ARGV");

	if(!defined $client_ip_as_string or !defined $data_direction or !defined $pps or !defined $action)
	{
		logit("usage: $usage");
		exit 0;
	}

	if("$action" eq "unban")
	{
		logit("action unban ignored");
		exit 0;
	}

	# check client_ip_as_string is ipv4
	($ver, $ip, $port) = parse_v4($client_ip_as_string) or mydie "'$client_ip_as_string' not an address\n";

	my $tmp_csv_fh	= new File::Temp( UNLINK => 0, TEMPLATE => 'dat_XXXXXXXX', DIR => $tmpcsvdir, SUFFIX => '.csv');
	my $thenaction	= "discard";
	my $description	= "API mitigation (fastnetmon)";
	my $blocktime	= 10;

	my $lines = 0;
	my $full_tcpdump_seen = 0;

	logit("processing tcpdump input ...");
	while (<STDIN>)
	{
		chomp $_;
		next if (/^$/);

		# fastnetmon
		if ($_ =~ /^Attack type:\s*(\w*)$/)									{ $attack_type = $1; next ;};
		if ($_ =~ /^Initial attack power:\s*(\d).*$/)						{ $Initial_attack_power = $1; next ;};
		if ($_ =~ /^Peak attack power:\s*(\d).*$/)							{ $Peak_attack_power = $1; next ;};
		if ($_ =~ /^Attack protocol:\s*(\w*)$/)								{ $attack_protocol = $1; next ;};
		if ($_ =~ /^Total incoming traffic:\s*(\d*).*$/)					{ $Total_incoming_traffic = $1; next ;};
		if ($_ =~ /^Attack direction:\s*(\w*)$/)							{ $Attack_direction = $1; next ;};
		if ($_ =~ /^Total outgoing traffic:\s*(\d).*$/)						{ $Total_outgoing_traffic = $1; next ;};
		if ($_ =~ /^Total incoming pps:\s*(\d).*$/)							{ $Total_incoming_pps = $1; next ;};
		if ($_ =~ /^Total outgoing pps:\s*(\d).*$/)							{ $Total_outgoing_pps = $1; next ;};
		if ($_ =~ /^Total incoming flows:\s*(\d).*$/)						{ $Total_incoming_flows = $1; next ;};
		if ($_ =~ /^Total outgoing flows:\s*(\d).*$/)						{ $Total_outgoing_flows = $1; next ;};
		if ($_ =~ /^Average incoming traffic:\s*(\d).*$/)					{ $Average_incoming_traffic = $1; next ;};
		if ($_ =~ /^Average outgoing traffic:\s*(\d).*$/)					{ $Average_outgoing_traffic = $1; next ;};
		if ($_ =~ /^Average incoming pps:\s*(\d).*$/)						{ $Average_incoming_pps = $1; next ;};
		if ($_ =~ /^Average outgoing pps:\s*(\d).*$/)						{ $Average_outgoing_pps = $1; next ;};
		if ($_ =~ /^Average incoming flows:\s*(\d).*$/)						{ $Average_incoming_flows = $1; next ;};
		if ($_ =~ /^Average outgoing flows:\s*(\d).*$/)						{ $Average_outgoing_flows = $1; next ;};
		if ($_ =~ /^Incoming ip fragmented traffic:\s*(\d).*$/)				{ $Incoming_ip_fragmented_traffic = $1; next ;};
		if ($_ =~ /^Outgoing ip fragmented traffic:\s*(\d).*$/)				{ $Outgoing_ip_fragmented_traffic = $1; next ;};
		if ($_ =~ /^Incoming ip fragmented pps:\s*(\d).*$/)					{ $Incoming_ip_fragmented_pps = $1; next ;};
		if ($_ =~ /^Outgoing ip fragmented pps:\s*(\d).*$/)					{ $Outgoing_ip_fragmented_pps = $1; next ;};
		if ($_ =~ /^Incoming tcp traffic:\s*(\d).*$/)						{ $Incoming_tcp_traffic = $1; next ;};
		if ($_ =~ /^Outgoing tcp traffic:\s*(\d).*$/)						{ $Outgoing_tcp_traffic = $1; next ;};
		if ($_ =~ /^Incoming tcp pps:\s*(\d).*$/)							{ $Incoming_tcp_pps = $1; next ;};
		if ($_ =~ /^Outgoing tcp pps:\s*(\d).*$/)							{ $Outgoing_tcp_pps = $1; next ;};
		if ($_ =~ /^Incoming syn tcp traffic:\s*(\d).*$/)					{ $Incoming_syn_tcp_traffic = $1; next ;};
		if ($_ =~ /^Outgoing syn tcp traffic:\s*(\d).*$/)					{ $Outgoing_syn_tcp_traffic = $1; next ;};
		if ($_ =~ /^Incoming syn tcp pps:\s*(\d).*$/)						{ $Incoming_syn_tcp_pps = $1; next ;};
		if ($_ =~ /^Outgoing syn tcp pps:\s*(\d).*$/)						{ $Outgoing_syn_tcp_pps = $1; next ;};
		if ($_ =~ /^Incoming udp traffic:\s*(\d).*$/)						{ $Incoming_udp_traffic = $1; next ;};
		if ($_ =~ /^Outgoing udp traffic:\s*(\d).*$/)						{ $Outgoing_udp_traffic = $1; next ;};
		if ($_ =~ /^Incoming udp pps:\s*(\d).*$/)							{ $Incoming_udp_pps = $1; next ;};
		if ($_ =~ /^Outgoing udp pps:\s*(\d).*$/)							{ $Outgoing_udp_pps = $1; next ;};
		if ($_ =~ /^Incoming icmp traffic:\s*(\d).*$/)						{ $Incoming_icmp_traffic = $1; next ;};
		if ($_ =~ /^Outgoing icmp traffic:\s*(\d).*$/)						{ $Outgoing_icmp_traffic = $1; next ;};
		if ($_ =~ /^Incoming icmp pps:\s*(\d).*$/)							{ $Incoming_icmp_pps = $1; next ;};
		if ($_ =~ /^Outgoing icmp pps:\s*(\d).*$/)							{ $Outgoing_icmp_pps = $1; next ;};
		if ($_ =~ /^Network incoming traffic:\s*(\d).*$/)					{ $Network_incoming_traffic = $1; next ;};
		if ($_ =~ /^Network outgoing traffic:\s*(\d).*$/)					{ $Network_outgoing_traffic = $1; next ;};
		if ($_ =~ /^Network incoming pps:\s*(\d).*$/)						{ $Network_incoming_pps = $1; next ;};
		if ($_ =~ /^Network outgoing pps:\s*(\d).*$/)						{ $Network_outgoing_pps = $1; next ;};
		if ($_ =~ /^Average network incoming traffic:\s*(\d).*$/)			{ $Average_network_incoming_traffic = $1; next ;};
		if ($_ =~ /^Average network outgoing traffic:\s*(\d).*$/)			{ $Average_network_outgoing_traffic = $1; next ;};
		if ($_ =~ /^Average network incoming pps:\s*(\d).*$/)				{ $Average_network_incoming_pps = $1; next ;};
		if ($_ =~ /^Average network outgoing pps:\s*(\d).*$/)				{ $Average_network_outgoing_pps = $1; next ;};
		if ($_ =~ /^Average packet size for incoming traffic:\s*(\d).*$/)	{ $Average_packet_size_for_incoming_traffic = $1; next ;};
		if ($_ =~ /^Average packet size for outgoing traffic:\s*(\d).*$/)	{ $Average_packet_size_for_outgoing_traffic = $1; next ;};

		# tcpdump: I'm missing a lot of information here
		if ($_ =~ /.*>.*$client_ip_as_string.*protocol:.*bytes.*ttl:.*/)
		{
			$full_tcpdump_seen = 1;

			# re-init
			$dst = $src = $protocol = $sport = $dport = $sport = $icmp_type = $icmp_code = $flags = $length = $ttl = $dscp = "";

			if ($_ =~ /protocol:.*icmp/)
			{
				($date, $time, $src_sport, $andgt, $dst_dport, $str, $protocol, $str, $frag, $str, $packets, $str, $length, $str, $str, $ttl, $str, $str, $ratio) =
				split(' ', $_);

			} elsif ($_ =~ /protocol:.*tcp/)
			{
				($date, $time, $src_sport, $andgt, $dst_dport, $str, $protocol, $str, $flags, $str, $frag, $str, $packets, $str, $length, $str, $str, $ttl, $str, $str, $ratio) = 
				split(' ', $_);

			} elsif ($_ =~ /protocol:.*udp/)
			{
				($date, $time, $src_sport, $andgt, $dst_dport, $str, $protocol, $str, $frag, $str, $packets, $str, $length, $str, $str, $ttl, $str, $str, $ratio) = 
				split(' ', $_);
			} 
			# else print "unknown IP protocol\n"; next;

			($src, $sport) = split(':', $src_sport);
			($dst, $dport) = split(':', $dst_dport);

			# Type 1 - Destination Prefix
			# Type 2 - Source Prefix
			# Type 3 - IP Protocol
			# Type 4 – Source or Destination Port
			# Type 5 – Destination Port
			# Type 6 - Source Port
			# Type 7 – ICMP Type
			# Type 8 – ICMP Code
			# Type 9 - TCP flags
			# Type 10 - Packet length
			# Type 11 – DSCP
			# Type 12 - Fragment Encoding

			# silently drop lines which does not have all info
			next if (!defined $src or !defined $sport or !defined $dst or !defined $dport or !defined $protocol or !defined $frag or !defined $packets or !defined $length or !defined $ttl or !defined $ratio or !defined $pps);

			# skip if not an address or portnumber (icmp has port 0 in output)
			($ver, $ip, $port) = parse_v4($src, $sport) or next;
			($ver, $ip, $port) = parse_v4($dst, $dport) or next;

			# skip if not numbers
			($ttl	=~ /[0-9]*/) or next;
			($ratio	=~ /[0-9]*/) or next;
			($pps	=~ /[0-9]*/) or next;

			# Clean up and assign default values, notice that port 0 does not officially exists and is defined as an ivalid port number. 
			# But valid Internet packets can be formed and transmitted to and from port 0 just as with any other ports

			if ($sport			eq "")		{ $sport		= ""; }
			if ($dport			eq "")		{ $dport		= ""; }
			if ($icmp_type		eq "")		{ $icmp_type	= ""; }
			if ($icmp_code		eq "")		{ $icmp_code	= ""; }
			if ($flags			eq "")		{ $flags		= ""; }
			if ($length			eq "")		{ $length		= ""; }
			if ($ttl			eq "")		{ $ttl			= ""; }
			if ($dscp			eq "")		{ $dscp			= ""; }
			# https://www.wains.be/pub/networking/tcpdump_advanced_filters.txt
			if ($frag			eq "" || $frag == 0)		{ $frag			= ""; }
			if ($attack_type	eq "")		{ $attack_type	= ""; }
			
			# icmp has no ports so set it to null
			if ($protocol		eq "icmp")
			{
				$sport = $dport = "";
			}
			$lines ++;
			print $tmp_csv_fh "$blocktime;$dst;$src;$protocol;$sport;$dport;$dport;$icmp_type;$icmp_code;$flags;$length;$ttl;$dscp;$frag;$thenaction;$description\n";
		}
		elsif($_ =~ /.*$client_ip_as_string.*<.*bytes.*packets.*/)
		{
			if (($full_tcpdump_seen == 0) && ($attack_type !~ m/.*_flood/))		# reduced TCP dump prepends the full -- and they are different
			{
				($dst_dport, $str, $src_sport, $str, $str, $str) =  split(' ', $_);

				($src, $sport) = split(':', $src_sport);
				($dst, $dport) = split(':', $dst_dport);

				$icmp_type = $icmp_code = $flags = $length = $ttl = $dscp = $frag = "";
				$protocol = $attack_protocol;
				$lines ++;
				print $tmp_csv_fh "$blocktime;$dst;$src;$protocol;$sport;$dport;$dport;$icmp_type;$icmp_code;$flags;$length;$ttl;$dscp;$frag\n";
			}
			else
			{
			#	logit("full_tcpdump_seen == $full_tcpdump_seen, unused input: $_");
			}
		}
		else
		{
		#	# non-tcpdump line ignored
		#	logit("unused input: $_");
		}
	}
	close($tmp_csv_fh)||mydie "close $tmp_csv_fh failed: $!";
	if ($full_tcpdump_seen == 1)
	{
		logit("wrote $lines lines to $tmp_csv_fh from tcpdump");
	}
	else
	{
		logit("wrote $lines lines to $tmp_csv_fh from truncated tcpdump");
	}

	if ($lines != 0) {

		my @csvfiles = ();

		my $isdigit     = qr/^[[:digit:]]+$/x;
		my ($blocktime,$dst,$src,$protocol,$sport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$thenaction,$description);

		opendir (DIR, $tmpcsvdir) or die "Could not open '$tmpcsvdir' $!";
		@csvfiles = grep(/\.csv$/,readdir(DIR));
		closedir(DIR);
		my $i = $#csvfiles + 1;
		logit("found $i files in '$tmpcsvdir'");

		foreach my $r (@csvfiles)
		{
			my %src_topports    = ();
			my %toplengths      = ();
			my $n = 0;

			my $type; my $optimize, my $version; my $attack_info;
			my $tmp;
			my $file    = path($tmpcsvdir . "/" . $r);

			my @lines = $file->lines_utf8;

			my $fragment_type = 0;
			my %tcp_flags   = ();

			# https://doc.pfsense.org/index.php/What_are_TCP_Flags
			foreach (split(/ /, "cwr ece urg ack psh rst syn fin"))
			{
				$tcp_flags{$_} = 0;
			}

			my $length_min  = 90000;    # jumbo package: count down
			my $length_max  = 0;        # max = 0: increment

			my $dst_prev    = "";
			my $dst_uniq    = 1;        # assume only one source

			my $src_prev    = "";
			my $src_uniq    = 1;        # assume only one source is targeting us


			my $sport_min   = 65536;    # minimum port number is max value (2^16) - decrement
			my $sport_max   = 0;

			my $dport_min   = 65536;    # initialize to max value - decrement real min value
			my $dport_max   = 0;        # initialize to min value - increment real max value


			# if ($head !~ /head/)                        { print("$file NOT ok: missing head");                      next;}
			if ($#lines < 2)                            { print("$file NOT ok: lines $#lines < 2");                 next;}

			my $rules_in_file = $#lines - 1; # base 0, subtract header/footer

			foreach my $line (@lines)
			{
				next if ($line =~ m/^head/);
				chomp($line);
				($blocktime,$dst,$src,$protocol,$sport,$dport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$thenaction,$description) = split(/;/, $line);

				# use this when calculating top10 $ipnum = ip2num("10.1.1.1")
				
				# Type 1    IPv4 destination address
				if ($dst_prev eq "")    # first line
				{
					$dst_prev   = $dst;
				}
				else
				{
					if ($dst ne $dst_prev)
					{
						$dst_uniq = 0;
					}
					$dst_prev = $dst;
				}

				# Type 2    IPv4 source address
				$src = "" if ($src eq "");
				if ($src_prev eq "")    # first line
				{
					$src_prev = $src;
					$length_min = 64;       # ethernet minimum packet length
					$length_max = 64;       # 
				}
				else
				{
					if ($src ne $src_prev)
					{
						$src_uniq = 0;
					}
					$src_prev = $src;
				}
				
				# Type 3    IPv4 protocol
				# fix names -> number
				for ($protocol) {
					s/tcp/=6/i;
					s/icmp/=1/i;
					s/udp/=17/i;
					s/gre/=47/i;
					# etc etc
				}
				# Identical in all lines

				# Type 4    IPv4 source or destination port
				# Type 5    IPv4 destination port
				# Type 6    IPv4 source port
				if ($sport =~ m/$isdigit/ && $sport_max =~ m/$isdigit/ && $sport_min =~ m/$isdigit/)
				{
					$sport_max  = max($sport_max,   $sport);
					$sport_min  = min($sport_min,   $sport);
					$src_topports{ $sport } += 1;
				}
				else
				{
					$sport_max = $sport_min = "";
				}

				if ($dport =~ m/$isdigit/ && $dport_max =~ m/$isdigit/ && $dport_min =~ m/$isdigit/)
				{
					$dport_max  = max($dport_max,   $dport);
					$dport_min  = min($dport_min,   $dport);
				}
				else
				{
					$dport_max = $dport_min = "";
				}

				# ICMP type and code (type 7 and 8) not reported by fastnetmon
				# Type 7    IPv4 ICMP type
				# Type 8    IPv4 ICMP code

				# Type 9    IPv4 TCP flags (2 bytes incl. reserveret bits)
				if ($flags ne '' && $flags ne '')
				{
					foreach (split(/,/, $flags))
					{
						$tcp_flags{$_} += 1;
					}
				}

				# Type 10   IPv4 package length
				if ($length =~ m/$isdigit/ && $length_min =~ /$isdigit/ && $length_max =~ m/$isdigit/)
				{
					$length_min = min($length_min,  $length);
					$length_max = max($length_max,  $length);
				}
				else
				{
					$length_max = $length_min = "";
				}

				# Type 11   IPv4 DSCP not reported by fastnetmon

				# Type 12   IPv4 fragment bits
			}

			# prepare bgp flowspec rules
			if ($src_uniq == 0)
			{
				$src = "0.0.0.0/0";
			}

			if ($sport =~ m//)
			{
				$sport = "";
			}
			else
			{
				if ($sport_max =~ m/$isdigit/ && $sport_min =~ m/$isdigit/)
				{
					if ($sport_min == $sport_max)
					{
						$sport = $sport_max;
					}
					else
					{
						$sport = ">=" . $sport_min . " <=" . $sport_max ;
					}
				}
				else
				{
					$sport = "";
				}
			}

			
			if ($dport =~ m/null/)
			{
				$dport = "";
			}
			else
			{
				if ($sport_max =~ m/$isdigit/ && $sport_min =~ m/$isdigit/)
				{
					if ($dport_min == $dport_max)
					{
						$dport = "=" . $dport_max ;
					}
					else
					{
						$dport = ">=" . $dport_min . " <=" . $dport_max ;
					}
				}
				else
				{
					$dport = "";
				}
			}
			
			if ($length_min =~ m/null/)
			{
				$length = "";
			}
			else
			{
				if ($length_max =~ m/$isdigit/ && $length_min =~ m/$isdigit/)
				{
					if ($length_min eq $length_max)
					{
						$length = "=" . $length_max;
					}
					else
					{
						$length = ">=" . $length_min . " <=" . $length_max ;

					}
				}
				else
				{
						$length = "";
				}
			}

			if ($fragment_type =~ /$isdigit/)
			{
				if ($fragment_type != 0)
				{
					$frag = "is-fragment";
				}
			}
			else
			{
				$frag = "";
			}

			my $tcp_match_flags = "";
			foreach my $key (keys %tcp_flags)
			{
				if($tcp_flags{$key} > 0)
				{
					$tcp_match_flags .= $key . " ";
				}
			}
			$tcp_match_flags =~ s/^\s+|\s+$//g;
			if ($tcp_match_flags eq '')
			{
				$tcp_match_flags = "";
			}

			# src / destination prefix is reported as a.b.c.d should be cidr
			if (index($dst, "/") == -1) {
				$dst = $dst . "/32";
			}
			if (index($src, "/") == -1) {
				$src = $src . "/32";
			}

			my $rule_file = "/tmp/rule.json";
			my $rule_data = <<EOF;
{
  "durationminutes":   "$blocktime",
  "destinationport":   "$dport",
  "sourceport":        "$sport",
  "icmptype":          "$icmp_type",
  "icmpcode":          "$icmp_code",
  "packetlength":      "$length",
  "dscp":              "$dscp",
  "description":       "$description",
  "destinationprefix": "$dst",
  "sourceprefix":      "$src",
  "thenaction":        "$thenaction",
  "fragmentencoding":  "$frag",
  "ipprotocol":        "$protocol",
  "tcpflags":           "$flags"
}
EOF
			# save json file with rules, then apply using API
			path($rule_file)->spew_utf8($rule_data);
			# TODO fix below
			#   - skriv om til shell/awk/sed/...
			#   - benyt https://metacpan.org/pod/release/SZBALINT/WWW-Curl-4.15/lib/WWW/Curl.pm
			#   - anvend my $curl=`curl http://whatever`
			my $system = `/usr/local/bin/client-api`;
		}
	}
	else {
		logit("lines = 0, not much to do with $tmp_csv_fh");
	}
	unlink($tmp_csv_fh) || die "unlink $tmp_csv_fh failed:!";
	logit("removed '$tmp_csv_fh'");
}

sub parse_v4(@) {
	my ($ip, $port) = @_;
	my @quad = split(/\./, $ip);
 
	return unless @quad == 4;
	{ return if (join('.', @quad) !~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) }	# prevent non digits from messing up next line
	for (@quad) { return if ($_ > 255) }
 
	if (!length $port) { $port = -1 }
	elsif ($port =~ /^(\d+)$/) { $port = $1 }
	else { return }
 
	my $h = join '' => map(sprintf("%02x", $_), @quad);
	return $h, $port
}
 
sub parse_v6($) {
	my $ip = shift;
	my $omits;
 
	return unless $ip =~ /^[\da-f:.]+$/i; # invalid char
 
	$ip =~ s/^:/0:/;
	$omits = 1 if $ip =~ s/::/:z:/g;
	return if $ip =~ /z.*z/;	# multiple omits illegal
 
	my $v4 = '';
	my $len = 8;
 
	if ($ip =~ s/:((?:\d+\.){3}\d+)$//) {
		# hybrid 4/6 ip
		($v4) = parse_v4($1)	or return;
		$len -= 2;
 
	}
	# what's left should be v6 only
	return unless $ip =~ /^[:a-fz\d]+$/i;
 
	my @h = split(/:/, $ip);
	return if @h + $omits > $len;	# too many segments
 
	@h = map( $_ eq 'z' ? (0) x ($len - @h + 1) : ($_), @h);
	return join('' => map(sprintf("%04x", hex($_)), @h)).$v4;
}
 
sub parse_ip($) {
	my $str = shift;
	$str =~ s/^\s*//;
	$str =~ s/\s*$//;
 
	if ($str =~ s/^((?:\d+\.)+\d+)(?::(\d+))?$//) {
		return 'v4', parse_v4($1, $2);
	}
 
	my ($ip, $port);
	if ($str =~ /^\[(.*?)\]:(\d+)$/) {
		$port = $2;
		$ip = parse_v6($1);
	} else {
		$port = -1;
		$ip = parse_v6($str);
	}
 
	return unless $ip;
	return 'v6', $ip, $port;
}

sub logit(@)
{
    my $msg = join(' ', @_);
    syslog("user|err", "$msg");
    my $now = strftime "%H:%M:%S (%Y/%m/%d)", localtime(time);
    print STDOUT "$now: $msg\n" if ($verbose);

    open(LOGFILE, ">>$logfile");
    print LOGFILE "$now: $msg\n";
    close(LOGFILE);
}

sub mydie(@)
{
	logit(@_);
	exit(0);
}

sub randstr(@) { join'', @_[ map{ rand @_ } 1 .. shift ] }
sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }


