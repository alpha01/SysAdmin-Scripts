#!/bin/bash

MACHINE=$1

nice -n 19 ionice -c 3 rsync -av -e 'ssh' --delete --exclude=/proc --exclude=/tmp --exclude=/sys --exclude=/dev --exclude=/server root@$MACHINE:/ /backups/$MACHINE/

if [ $? -eq 0 ]
then
        su - nagios -c "/bin/bash /usr/local/nagios/libexec/send_backup_status '$MACHINE Backup Status' 0  'OK - rsync completed without errors.'"
else
        su - nagios -c "/bin/bash /usr/local/nagios/libexec/send_backup_status '$MACHINE Backup Status' 1  'WARNING - rsync completed with errors!'"

fi
