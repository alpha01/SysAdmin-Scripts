#!/usr/bin/perl -w

# Deploy new VirtualBox Virtual Machines, the easy way.
# Written by Tony Baltazar. September 2013.
# Email: root@rubyninja.org

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



use strict;
use Getopt::Long;
use Filesys::Df;
use POSIX;
use File::Basename;
use lib dirname(__FILE__);
use AddToDHCP;



my %options;
GetOptions(\%options, "name|n:s", "disk|d:i",  "memory|m:i", "ostype|o:s", "help");


my $VIRTUAL_MACHINES_LOCATIONS = '/home/tony/VirtualBox VMs';
my $DHCP_SERVER = 'DHCP-SERVER-IP-HERE';


if ($options{help}) {
	usage();
	exit 1;
} elsif ($options{name} && $options{disk} && $options{memory}) {

	exit 1 unless check_available_memory();
	exit 1 unless ostype();
	exit 1  unless createvm();
	clean_up() unless modifyvm();
	clean_up() unless create_hd();
	clean_up() unless configure_hd();
	push_to_dhcp();

} else {
	usage();
	exit 1;
}




### Subroutines ###

sub usage {
print <<EOF;

$0: Creates a new VirtualBox Virtual Machine.

Syntax: $0 [--help|--name=<VM-name> --disk=<size-in-MB> --memory=<size-in-MB>]

   --help   | -h  : This help message
   --name   | -n  : Name of the new virtual machine instance.
   --disk   | -d  : Disk Size in MB.
   --memory | -m  : Memory in MB.

Optionally,
   --ostype | -o  : Operating System type.

EOF
}


sub ostype {
	my @ostype_list = `VBoxManage list ostypes|grep ID|awk '{print \$NF}'`;
	chomp(@ostype_list);

	my $os_start = 0;
	my $output_ostype_string;
	
	foreach my $type (@ostype_list) {
		$output_ostype_string .= sprintf("%-20s %-20s", $type, "[ $os_start ]");
		if ($os_start % 3 == 0) {
			$output_ostype_string .= "\n";
		} else {
			$output_ostype_string .= "\t";
		} 

		$os_start += 1;
	}

	if ( ($options{ostype}) && (grep $_ eq $options{ostype}, @ostype_list) ) {
		return 1;
	} else {
		print "Unknown OS type: $options{ostype}\n\n" if($options{ostype});
	
		print $output_ostype_string;
		print "\nNo OS type specified, choose the type (default [38] ): ";
		chomp(my $os_input = <STDIN>);

		if (! $os_input) {
			$options{ostype} = $ostype_list[38];
 		} elsif ($os_input =~ /\D/) {
			print "Invalid OS type: $os_input\n";
			return 0;
		} else {
			unless ($ostype_list[$os_input]) {
				print "Invalid OS type: $os_input\n";
				return 0;
			} else {
				$options{ostype} = $ostype_list[$os_input];
			}
		}
	}	

}


sub check_available_memory {
	my $available_memory = `free -m | grep buffers/cache |awk '{print \$NF}'`;
	chomp($available_memory);

	if ($options{memory} > $available_memory) {
		print "Not enough memory available.\n";
		print "\tFree memory: $available_memory MB\n";
		return 0;
	} elsif ($available_memory - $options{memory} <= 512) {
		print "Warning: If VM is created, available memory for host machine is going to be criticallly low!!\n";
		print "\tFree memory: $available_memory MB\n";
		return 0;
	} else {
		return 1;
	}

}


sub createvm {
	print "Creating virtual machine... \n\tName: $options{name}\n\tMemory: $options{memory}\n\tDisk Size: $options{disk}\n\tOS Type: $options{ostype}\n\n\n";

	system("VBoxManage createvm --name '$options{name}' --ostype $options{ostype} --register 2>/dev/null");
	if ($? != 0) {
		print "Failed to create Virtual Machine.\n";
		return 0;
	} else {
		return 1;
	}

}


sub create_hd {
	my $disk = df('/');
	my $disk_free = floor($disk->{bfree} / 1000);

	if ($options{disk} >= $disk_free) {
		print "Not enough space to create the virtual machine.\n";
		print "\tAvailable: $disk_free MB\n";
		return 0;
	} elsif ($disk_free - $options{disk} <= 2) {
		print "Warning: host machine is going to be critically low in disk space!!\n";
		return 0;
	} else {
		chdir("$VIRTUAL_MACHINES_LOCATIONS/$options{name}");
		system("VBoxManage createhd --filename $options{name} --size $options{disk} 2>/dev/null");
		if ($? != 0) {
			print "Failed to createhd\n";
			return 0;
		} else {
			return 1;
		}
	}

}


sub configure_hd {
	chdir("$VIRTUAL_MACHINES_LOCATIONS/$options{name}/");

	system("VBoxManage storagectl '$options{name}' --name 'SATA Controller' --add sata --controller IntelAhci --bootable on 2>/dev/null");
	if ($? != 0) {
		print "Failed to create storage controller\n";
		return 0;
	} 

	system("VBoxManage storageattach '$options{name}' --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium $options{name}.vdi");
	if ($? != 0) {
		print "Failed to attach drive to VM\n";
		return 0;
	} else {
		return 1;
	}
}


sub modifyvm {
	system("VBoxManage modifyvm '$options{name}' --memory $options{memory} --acpi on --boot1 dvd --nic1 bridged --bridgeadapter1 eth0 2>/dev/null");
	if ($? != 0) {
		print "Failed to modifyvm\n";
		return 0;
	} else {
		return 1;
	}
}


sub push_to_dhcp {
	chomp (my $mac_address_vm = `VBoxManage showvminfo '$options{name}'|grep MAC|awk '{print \$4}'`);
	chop($mac_address_vm); #gets rid of trailing comman (,)
	my $mac_address = join(':', grep {length > 0} split(/(..)/, $mac_address_vm));
	
	my $push_to_dhcp_ob = AddToDHCP->new;
	$push_to_dhcp_ob->name($options{name});
	$push_to_dhcp_ob->hardware($mac_address);
	$push_to_dhcp_ob->dhcp($DHCP_SERVER);

	$push_to_dhcp_ob->add_to_dhcp;	
}


sub clean_up {
	print "Cleaning up failed VM installation/configuration...\n\n";

	system("VBoxManage unregistervm '$options{name}' --delete");
	if ($? != 0) {
		print "Clean up failed, something is seriously fucked.\n";
		exit 1;
	} else {
		exit 0;
	}
}
