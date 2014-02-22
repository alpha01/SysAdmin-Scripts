#!/usr/bin/perl -w

# Tony Baltazar. root[@]rubyninja.org

use strict;
use Getopt::Long;




my %options;
GetOptions(\%options, "host|H:s", "port|p:i",  "rport|R:s","file|f:s", "help");


if ($options{help}) {
	usage();
} elsif ($options{host} && $options{port} && $options{file}) { 
	chdir('/tmp');

	my $cmd_str = ( $options{rport} ?  "/usr/bin/tftp -R $options{rport}:$options{rport} $options{host} $options{port} -c get $options{file}" : "/usr/bin/tftp $options{host} $options{port} -c get $options{file}");

	my $cmd = `$cmd_str`;
	if ($? != 0) {
		print "CRITICAL: $cmd";
		system("rm -f /tmp/$options{file}");
		exit 2;
	} else {
		if (! -z "/tmp/$options{file}" ) {
			print "TFTP is ok.\n$cmd";
			system("rm -f /tmp/$options{file}");
			exit 0;
		} else {
			print "WARNING: $cmd";
			system("rm -f /tmp/$options{file}");
			exit 1;
		}
	}

} else {
	usage();
}



sub usage {
print <<EOF;

$0: TFTP monitor check Nagios plugin.

Syntax: $0 [--help|-H=<TFTP server> --port=<TFTP Port> --file=<Test file>]

   --host | -H  : TFTP server.
   --port | -p  : TFTP Port.
   --file | -m  : Test file that will be downloaded.
   --help | -h  : This help message.

Optionally,
   --rport | -R : Explicitly force the reverse originating connection's port.

EOF
exit 3;
}
