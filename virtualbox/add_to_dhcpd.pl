#!/usr/bin/perl

# Written by Tony Baltazar. root[@]rubyninja.org. October 2013.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA


use Net::ISC::DHCPd::Config;
use Getopt::Long;
use Data::Dumper;
use File::Copy;
use POSIX;

use strict;



my $DEBUG = 0;


my %options;
GetOptions(\%options, "name|n:s", "hardware|h:s", "help");

my $DHCP_CONF_FILE = '/etc/dhcp/dhcpd.conf';
my $NETWORK_RANGE = '192.168.1.20-129';



if ($options{help}) {
	usage();
	exit 1;
} elsif ($options{name} && $options{hardware}) {
	main();
} else {
	usage();
	exit 1;
}



sub main {
	my $config = Net::ISC::DHCPd::Config->new(file => $DHCP_CONF_FILE);

	# parse the config
	$config->parse;


	if ($config->find_hosts({ name => $options{name} }) ) {
		print "$options{name} already exists!\n";
		exit 1;
	}	

	$config->add_host({
		name => $options{name},
		keyvalue => [{ name => 'hardware', value => "ethernet $options{hardware}" },
			 	{ name => 'fixed-address', value => get_ip() }],
		#filename => [{ file => 'pxelinux.0' }],
		#options => [{name => 'namehere', value => 'valuehere'}],
	});

	$config->captured_to_args;
	$config->parse;


	print "Backing up /etc/dhcp/dhcpd.conf to /etc/dhcp/backup-configs/ ...\n\n";
	copy( '/etc/dhcp/dhcpd.conf', strftime("/etc/dhcp/backup-configs/dhcpd.conf_%Y%m%d%H%S", localtime) ) or die "Copy failed: $!";

	print "Generating new dhcpd.conf file..\n";
	open(my $fh, '>', $DHCP_CONF_FILE) or die "Cannot open > $DHCP_CONF_FILE: $!";
	print {$fh} $config->generate_config_from_children;
	close($fh);

	system('/etc/init.d/isc-dhcp-server restart');
	if ($? != 0) {
		print "dhcpd restart failed!\n";
	} else {
		print "Successfully restarted dhcpd.\n\n";
	}

	print Dumper($config) if $DEBUG;
}


# ghetto shit
sub get_ip {
	my @available_hosts = `nmap -sP -v $NETWORK_RANGE|grep 'is down.'`;
	if ($? != 0) {
		print "Nmap is not installed or invalid network range.\n\n";
		exit 1;
	}

	for my $ip (@available_hosts) {
		my @split_ip = split " ", $ip;
		my $grep_search = `grep $split_ip[1] $DHCP_CONF_FILE`;
		if ($grep_search eq "" ) {
			return $split_ip[1];
			last;
		}
	}
}


sub usage {
print <<EOF;

$0: Adds a statically assign host to ISC-DCHPd server.

Syntax: $0 [--help|--name=<Hostname> --hardware=<MAC address>]

   --name     | -n  : Host name.
   --hardware | -h  : MAC address.

EOF

}
