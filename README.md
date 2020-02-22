# btrfs-backup

## Purpose

This BTRFS backup script is based on the [official Wiki steps](https://btrfs.wiki.kernel.org/index.php/Incremental_Backup).

It aims to be very simple and straightforward, so there is no plan to support historical archives or whatsoever.

## Usage

Edit the configuration file, to adjust paths within the `SOURCES` and `TARGET` variables to your needs.

Then:

```
./btrfs-backup.sh
```

## Recovering

Send the snapshot to the new BTRFS media:

```
% sudo btrfs send /media/BACKUP | sudo btrfs receive /media/DEST
```

Once completed, take note ofthe subvolume `ID`:

```
% sudo btrfs subvolume list /media/DEST
```

Using this `ID`, let's say `259`, set it as the volume's default:

```
% sudo btrfs subvolume set-default 259 /media/DEST
% sudo btrfs subvolume get-default /media/DEST
```

For changes to take effect, remount the disk or reboot.

## TODO

* improve error handling and corner cases
* replace path checks with appropriate BTRFS subvolume tests