#!/bin/bash

/usr/sbin/kdb5_util dump /var/kerberos/krb5kdc/slave_datatrans && /usr/sbin/kprop afs2.rubyninja.org

if [ "$?" != "0" ]
then
	echo "Error : syncing to slave KDC!!!"
	tail -n 5 /var/log/krb5kdc.log
	exit 1; 
fi

