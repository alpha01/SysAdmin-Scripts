#!/usr/bin/env php
<?php

$ip = 'IPADDRESS';

$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, 'http://automation.whatismyip.com/n09230945.asp');
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$remote_ip = curl_exec($ch);
curl_close($ch);


if (($ip != $remote_ip) && ($remote_ip != '')) {
	mail('root@rubyninja.org', "Alert new publilc IP detected: $remote_ip", "Old IP: $ip\nNew IP: $remote_ip", "From:alert@rubyninja.net\n");
}
