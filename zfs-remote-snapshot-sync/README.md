# zfs-remote-snapshot-sync

## Overview
This tool is designed to push a dataset snapshot from a local zfs storage pool to a storage pool on a remote server.  It transfers the latest available local snapshot for the dataset, so it is best when used in combination with a tool such as zfs-auto-snapshot.  The script utilizes ssh for the network channel, so it is recommend to configure passwordless ssh from the local server to the destination server. Then this script can simply be executed from cron as the root user account.

When the script runs, it attempts to transfer the lastest local snapshot of the specified dataset to the storage pool on the remote server. This is ___NOT___ a bi-directional sync, so if the script detects changes on the destination copy of the dataset, it will attempt to rollback changes on destination to the last referenced snapshot (com.tessercode:snapshot_reference). It is important to monitor the exit status of this script to verify it is running correctly.

## Script Setup
Once you've copied the script to your server, please edit the following variables to match your environment:

#### Name of the dataset to sync
DATASET=""

#### Name of local storage pool containing dataset
SRC_POOL=""

#### Name of remote server that dataset should be transferred to
DEST_SERVER=""

#### Name of storage pool on remote server
DEST_POOL=""

## Sync User Setup
Create a zfs_sync user on both the local and remote servers and setup passwordless ssh access between the two systems.  Once that is in place, password based authentication for this user can be disabled.

On both the local and remote systems, use the provided zfs.sudo file to allow the zfs_sync user to run the specified zfs commands without being prompted for a password.
