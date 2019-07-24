# zfs-remote-snapshot-sync

## Overview
This tool is designed to push a dataset snapshot from a local zfs storage pool to a storage pool on a remote server.  It transfers the latest available local snapshot for the dataset, so it is best when used in combination with a tool such as zfs-auto-snapshot.  The script utilizes ssh for the network channel, so it is recommend to configure passwordless ssh from the local server to the destination server. Then this script can simply be executed from cron as the root user account.

## Setup
Once you've copied the script to your server, please edit the following variables to match your environment:

#### Name of the dataset to sync
DATASET=""

#### Name of local storage pool containing dataset
SRC_POOL=""

#### Name of remote server that dataset should be transferred to
DEST_SERVER=""

#### Name of storage pool on remote server
DEST_POOL=""
