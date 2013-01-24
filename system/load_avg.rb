#!/usr/bin/env ruby

# rubyninja load monitoring script.

require 'net/smtp'


load_avg = %x[cat /proc/loadavg]
cpu_util = %x[sar -u 1 1 | awk -F ' ' '{print $NF}']

cpu_util_arr = cpu_util.lines.to_a
final_cpu_usage = cpu_util_arr[-1]

load_results = load_avg.split(' ')


$load5 = load_results[0]
$load10 = load_results[1]
$load15 = load_results[2]

# Load Thresholds
load5_threshold = 5
load10_threshold = 5
load15_threshold = 5
cpu_threshold = 80 # (20% in use)


def send_email(to, opts={})
	opts[:server]	   ||= 'localhost'
	opts[:from]	   ||= 'monitor@rubyninja.net'
	opts[:from_alias]  ||= "Server Alert: #{ENV['HOSTNAME']}"
	opts[:subject]     ||= "High load on #{ENV['HOSTNAME']}"
	opts[:body]        ||= "Load Average:#$load5, #$load10, #$load15"
						    
msg = <<END_OF_MESSAGE
from: #{opts[:from_alias]} <#{opts[:from]}>
to: <#{to}>
subject: #{opts[:subject]}

#{opts[:body]}
END_OF_MESSAGE
							       	       
	Net::SMTP.start(opts[:server]) do |smtp|
		smtp.send_message msg, opts[:from], to
	end
end


if ($load5.to_i >= load5_threshold) && ($load10.to_i >= load10_threshold) && ($load15.to_i >= load15_threshold)

	if final_cpu_usage.to_i >= cpu_threshold

		server_top = %x[top -n 1 -b]

		send_email("txt@perlninja.pl")
		send_email("root@perlninja.pl", :body => "#{server_top}")                                  

	end
end
