#!/bin/bash

virtualbox_vms=(bashninja rubyninja Debian ubuntu Windows_Server_2003 Solaris monitor FreeBSD)


for vm in ${virtualbox_vms[@]}
do
        vm_check=`ps aux |grep -e "/usr/lib/virtualbox/VBoxHeadless -s \$vm$"|awk '{print $2}'`

        if [ "$vm_check" != "" ]
        then
                echo "$vm is currently active. PID: $vm_check"
        else
                echo "Starting VirtualBox VM: $vm"
                VBoxHeadless -s $vm &
                sleep 15
        fi
done
