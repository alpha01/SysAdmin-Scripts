#!/usr/bin/env perl
use strict;
# Randomizes the NIC's mac address to pretend to be an Apple device.
# To auto randomize every time the computer starts, add this script to /etc/rc.local
# Written by: Tony Baltazar May 2011.
# Email: root[@]rubyninja.org

# TODO: get this working on wireless interfaces (nmcli?)

# Change this to which ever interface you want to randomize
my $INTERFACE = 'eth0';

sub random_mac_addrr() {

        # known Apple mac address prefixes
        my @hw = qw(00:1c:b3 00:1e:c2 00:1f:5b 00:1f:f3 00:21:e9 00:22:41 00:23:12 00:23:32 00:23:6c 00:23:df 00:24:36 00:25:00 00:25:4b 00:25:bc 00:26:08 00:26:4a 00:26:b0 00:26:bb 04:0c:ce 04:1e:64 10:93:e9 14:5a:05 24:ab:81 28:e7:cf 34:15:9e 40:30:04 40:d3:2d 44:2a:60 58:1f:aa 58:b0:35 60:fb:42 64:b9:e8 7c:6d:62 8c:58:77 90:84:0d 98:03:d8 a4:b1:97 a4:d1:d2 d4:9a:20 d8:30:62 d8:9e:3f f8:1e:df);


        my @mac_chars = ('a'..'f','0'..'9');

        my $mac_address = $hw[int(rand($#hw))];

        foreach (0..2) {
                my $random_str = $mac_chars[int(rand($#mac_chars))];
                my $random_str2 = $mac_chars[int(rand($#mac_chars))];
                $mac_address .= ":$random_str$random_str2";
	}

        return $mac_address;
}


my $new_mac_addr = random_mac_addrr();

system("ifconfig $INTERFACE down hw ether $new_mac_addr");
system("ifconfig $INTERFACE  up");

