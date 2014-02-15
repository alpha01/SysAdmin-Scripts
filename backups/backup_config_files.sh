#!/bin/bash

cd /home/backups/SERVER_BACKUPS/main_conf_files

tar -czvf conf_files_$(date +%Y%m%d_%H%M).tar.gz /etc/varnish/default.vcl /etc/sysconfig/varnish /etc/nginx/nginx.conf /etc/sysconfig/iptables

