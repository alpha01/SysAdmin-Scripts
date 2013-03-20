#!/bin/bash
# Tony's humble ZFS snapshot creation script.

ZFS_POOL=$1
MACHINE=$2
SNAPSHOT_NAME="$(date +%Y%m%d_%H%M)"


echo "Creating ZFS snapshot.."
/usr/local/sbin/zfs snapshot "$ZFS_POOL/$MACHINE@$SNAPSHOT_NAME"

if [ $? -eq 0 ]
then
        echo "Successfully created ZFS snapshot: $ZFS_POOL/$MACHINE@$SNAPSHOT_NAME"
        echo "Available snapshots for $ZFS_POOL/$MACHINE:"
        /usr/local/sbin/zfs list -r -t snapshot -o name,creation,used "$ZFS_POOL/$MACHINE"
        exit 0
else
        echo "ERROR: failed to create ZFS snapshot!!!"
        exit 1
fi

