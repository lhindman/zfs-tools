#!/bin/bash 
# Author:  Luke Hindman
# Date: Tue Apr 28 10:44:13 MDT 2015
# Revised: Wed Jul 24 16:29:00 UTC 2019
# Description:  Replicate the latest available snapshot from the source 
#      pool/dataset to the destination server/pool.  First attempt to perform
#      an incremental transfer.  If that is not possible or fails, revert to
#      a full transfer.  
#
#    Usage:  zfs-remote-snapshot-sync.sh  
#

# Name of the dataset to sync
DATASET="home"

# Name of local storage pool containing dataset
SRC_POOL="cspool"

# Name of remote server that dataset should be transferred to
DEST_SERVER="wrecker.fantasy.org"

# Name of storage pool on remote server
DEST_POOL="fountain"




#
# Set default values for internal variables
#
snap_ref=""
incremental_xfer=true
zpool="sudo /sbin/zpool"
zfs="sudo /sbin/zfs"
ssh="/usr/bin/ssh"

#
# Check if the destination pool is available.  If not, terminate the script.
#
if ! ${ssh} ${DEST_SERVER} ${zpool} list ${DEST_POOL} 1>/dev/null 2>&1;
then
   echo "Error: ${DEST_POOL} on ${DEST_SERVER} is not available"
   exit 1
fi

#
# Determine if the snapshot_reference property is set for the destination dataset, if so
#  retrieve the value and perform an incremental transfer
# If not available, perform full transfer
#
if ${ssh} ${DEST_SERVER} ${zfs} get com.tessercode:snapshot_reference ${DEST_POOL}/${DATASET} 1>/dev/null 2>&1;
then
   snap_ref=`${ssh} ${DEST_SERVER} ${zfs} get com.tessercode:snapshot_reference ${DEST_POOL}/${DATASET} | tail -1 | tr -s ' ' | cut -d ' ' -f 3`
   if [ "${snap_ref}" == "" ];
   then
      incremental_xfer=false
      echo "Warning: The com.tessercode:snapshot_reference property value is not set on ${DEST_POOL}/${DATASET}, performing full transfer"
   fi
else
   incremental_xfer=false
   echo "Warning: The com.tessercode:snapshot_reference property does not exist on ${DEST_POOL}/${DATASET}, performing full transfer"
fi   


#
# Determine the latest available snapshot for the source dataset
# Terminate the script if no snapshots are available
#

snap_latest=`${zfs} list -t snapshot -o name,creation -s creation | sed '1d' |grep "${SRC_POOL}/${DATASET}" | tail -1 | tr -s ' ' | cut -d ' ' -f 1 | sed "s/${SRC_POOL}\///"`
if [ "${snap_latest}" == "" ];
then
   echo "Error: No snapshots available on ${SRC_POOL}/${DATASET}"
   exit 1
fi


#
# Sanity Check... 
#  Verify that the reference snapshot for the destination dataset is available for
#  the source dataset. 
# If not available, perform full transfer
#
if [ "${incremental_xfer}" == true ];
then
 
   result=`${zfs} list -t snapshot ${SRC_POOL}/${snap_ref} | sed '1d'`
   if [ "${result}" == "" ];
   then
      echo "Warning: The reference snapshot is not available on ${SRC_POOL}/${DATASET}, performing full transfer"
      incremental_xfer=false
   fi
fi

#
# Check if the latest available snapshot on the source is the same as the reference
#  snapshot on the destination
# Terminate the transfer if the snapshots are the same.
#

echo "+------------------------+"
echo "|   Operation Summary    |"
echo "+------------------------+"

echo "Source pool/dataset:  ${SRC_POOL}/${DATASET}"
echo "Destination pool/dataset:  ${DEST_POOL}/${DATASET} @ ${DEST_SERVER}"
echo "Reference snapshot:  ${snap_ref}"
echo "Latest snapshot:  ${snap_latest}"
if [ "${incremental_xfer}" == true ];
then
   echo "Transfer Method:  Incremental"
else
   echo "Transfer Method:  Full"
fi

if [ "${snap_ref}" == "${snap_latest}" ];
then
   echo "Info: The latest snapshot from ${SRC_POOL}/${DATASET} is already on ${DEST_POOL}/${DATASET} @ ${DEST_SERVER}"
else
   #
   # If incremental == TRUE, perform incremental transfer Else perform full transfer
   #
   if [ "${incremental_xfer}" == true ];
   then
      if ! ${ssh} ${DEST_SERVER} ${zfs} rollback ${DEST_POOL}/${snap_ref} -r;
      then
         echo "Error:  Rollback of ${DEST_POOL}/${DATASET} @ ${DEST_SERVER} to ${snap_ref} failed"
         exit 1
      fi
      if ! ${zfs} send -i ${SRC_POOL}/${snap_ref} ${SRC_POOL}/${snap_latest} | ${ssh} ${DEST_SERVER} ${zfs} recv ${DEST_POOL}/${DATASET};
      then
         echo "Error:  Unable to perform sync.  If local modifications exist on destination, use the following command to rollback to reference:"
         echo "   zfs rollback ${DEST_POOL}/${snap_ref} -r "
         exit 1
      fi
   else
      if ! ${zfs} send ${SRC_POOL}/${snap_latest} | ${ssh} ${DEST_SERVER} ${zfs} recv ${DEST_POOL}/${DATASET};
      then 
         echo "Error:  The sync did not complete successfully"
         exit 1
      fi
   fi
fi

#
# Update the reference_snapshot user-defined property on destination dataset with 
#  latest transfered snapshot 
#

${ssh} ${DEST_SERVER} ${zfs} set com.tessercode:snapshot_reference=${snap_latest} ${DEST_POOL}/${DATASET} 

