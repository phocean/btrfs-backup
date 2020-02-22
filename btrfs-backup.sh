#!/bin/bash

## Simple BTRFS backup script based on official Wiki:
## https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
## Usage : ./btrfs-backup.sh
## See configuration section to adjust your paths.

## Recovery steps to any BTRFS file system:
## % sudo btrfs send /media/BACKUP | sudo btrfs receive /media/DEST
## % sudo btrfs subvolume list /media/DEST
## Take note the subvolume ID, let's say 259, and:
## % sudo btrfs subvolume set-default 259 /media/DEST
## % sudo btrfs subvolume get-default /media/DEST
## Remount or reboot.

### CONFIG ###
SOURCES=(/ /opt /usr/local /home) # paths to backup
TARGET=/run/media/phocean/backup/thinkpad # target backup media path
### END CONFIG ###

set -e
PATH=$(/usr/bin/getconf PATH)

if [ ! -d $TARGET ]; then
    echo -e "\n[!] Mount the backup media first. Exiting...\n"
    exit 1
fi

for SOURCE in ${SOURCES[@]}; do
    echo -e "[+] Processing backup of $SOURCE"
    # prepare target backup path
    if [ $SOURCE == "/" ]; then
        SNAPSHOTPATH=$TARGET/root
    else
        SNAPSHOTPATH=$TARGET$SOURCE
    fi
    if [ ! -d $SOURCE ]; then
        echo -e "[+] Source not found. Skipping..."
        break
    fi
    # create missing folders
    if [ ! -d $SNAPSHOTPATH ]; then
        echo -e "[+] Preparing backup path"
        mkdir -p $SNAPSHOTPATH
    fi
    # check if bootstrap snapshot is needed
    if [ ! -d $SOURCE/BACKUP ]; then
        echo -e "[+] Preparing bootstrap"
        sudo btrfs subvolume snapshot -r $SOURCE $SOURCE/BACKUP
        sync
        ## send snapshot to backup media
        echo -e "[+] Sending bootstrap to backup media"
        sudo btrfs send $SOURCE/BACKUP | sudo btrfs receive $SNAPSHOTPATH
        ## bootstrap done, go ahead with next subvolume (skip incremental this time)
        break
    fi
    # do incremental backup
    ## create new snapshot on the source
    echo -e "[+] Creating new snapshot"
    sudo btrfs subvolume snapshot -r $SOURCE $SOURCE/BACKUP-new
    sync
    ## send diffences from parent snapshot to the backup media
    echo -e "[+] Sending incremental snapshot to backup media"
    sudo btrfs send -p $SOURCE/BACKUP $SOURCE/BACKUP-new | sudo btrfs receive $SNAPSHOTPATH
    ## cleanup (deleting)
    echo -e "[+] Cleaning up history"
    sudo btrfs subvolume delete $SOURCE/BACKUP
    sudo mv $SOURCE/BACKUP-new $SOURCE/BACKUP
    sudo btrfs subvolume delete $SNAPSHOTPATH/BACKUP
    sudo mv $SNAPSHOTPATH/BACKUP-new $SNAPSHOTPATH/BACKUP
    echo -e "[+] Done for $SOURCE"
done

echo -e "[+] All done, exiting."
exit 0