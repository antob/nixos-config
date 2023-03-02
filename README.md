# My NixOS configuration

## Setup

### Partitioning

Optional, but just to ensure no remnants of the secure erase mess anything up, zap the drive.

```
sgdisk --zap-all *DRIVE*
```

Now do the actual partitioning. You can adjust the sizes of the EFI partition (though at least 300 MB is recommended) and the swap partition (if you have a lot of storage, RAM size + 2GB is good). We are naming drives here so we can use the names instead of potentially volatile names like '/dev/sda'.

```
sgdisk --clear --new=1:0:+1GiB --typecode=1:ef00 --change-name=1:ESP --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsystem *DRIVE*
```

Verify that the partitions are set up properly.

```
fdisk -l
```

### Create the encrypted system partition. Note that we explicitly specify LUKS2 as well as our encryption parameters.

```
cryptsetup luksFormat --type luks2 --align-payload=8192 -s 256 -c aes-xts-plain64 /dev/disk/by-partlabel/cryptsystem
```

Open the new encrypted system partition.

```
cryptsetup open /dev/disk/by-partlabel/cryptsystem system
```
