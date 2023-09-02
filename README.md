# My NixOS configuration

## Setup

### Partitioning

Optional, but just to ensure no remnants of the secure erase mess anything up, zap the drive.

```
# sgdisk --zap-all *DRIVE*
```

Now do the actual partitioning. You can adjust the sizes of the EFI partition (though at least 300 MB is recommended). We are naming drives here so we can use the names instead of potentially volatile names like '/dev/sda'.

```
# sgdisk --clear --new=1:0:+1GiB --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsystem *DRIVE*
```

Verify that the partitions are set up properly.

```
# fdisk -l
```

### Create the encrypted system partition. Note that we explicitly specify LUKS2 as well as our encryption parameters.

```
# cryptsetup luksFormat --type luks2 --align-payload=8192 -s 256 -c aes-xts-plain64 /dev/disk/by-partlabel/cryptsystem
```

Open the new encrypted system partition.

```
# cryptsetup open /dev/disk/by-partlabel/cryptsystem system
```

### Btrfs

Create the filesystem

```
# mkfs.btrfs --label system /dev/mapper/system
```

Mount at root

```
# mount -t btrfs LABEL=system /mnt
```

Create the root subvolume (this will be '/' on the final system)

```
# btrfs subvolume create /mnt/@root
```

Create the home subvolume

```
# btrfs subvolume create /mnt/@home
```

Create the nix directory subvolume (this will hold all NixOS data)

```
# btrfs subvolume create /mnt/@nix
```

Create a subvolume for persistent storage

```
# btrfs subvolume create /mnt/@persist
```

Create a subvolume for swap

```
# btrfs subvolume create /mnt/@swap
```

Unmount root so we can change mount options

```
# umount -R /mnt
```

Remount the root subvolume with options. The compression here is optional, zstd offers the best storage but you may prefer a different algorithm for speed, or omit entirely. Only use ssd if you are on an SSD. You can also enable atime if desired, but it comes with overhead.

```
# mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@root LABEL=system /mnt
```

Mount the nix and persist subvolumes (same deal with options as previous step)

```
# mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@nix LABEL=system /mnt/nix
# mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@persist LABEL=system /mnt/persist
```

Mount the swap subvolume. Note: Do not use compression for swap subvolume.

```
# mount -t btrfs -o defaults,x-mount.mkdir,compress=none,ssd,noatime,subvol=@swap LABEL=system /mnt/swap
```

### EFI System Partition

Format the partition as FAT-32, with label 'EFI'

```
# mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
```

Make the mount directory

```
# mkdir /mnt/efi
```

Mount the ESP

```
# mount LABEL=EFI /mnt/efi
```

### Swap

Create the swapfile. Filesize set to RAM size + 2GB is good. The `mkswapfile` command requires at least version 6.1 of `btrfs-progs`.

```
# btrfs filesystem mkswapfile --size 10G /mnt/swap/swapfile
```

Calculate swapfile offset value to put in `resume_offset` kernel parameter.

```
# btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile
```

Activate the swap file:

```
# swapon /mnt/swap/swapfile
```

### Generate config

Install git.

```
# nix-env -f '<nixpkgs>' -iA git
```

Generate config for current machine.

```
# nixos-generate-config --root /mnt
```

Clone your config flake and cd into the folder.

```
# git clone https://github.com/antob/nixos-config /mnt/etc/nixos/antob
# cd /mnt/etc/nixos/antob
```

Add `resume_offset` kernel parameter using value calculated in a previous step.

```
# In relevant host hardware file (e.g `systems/x86_64-linux/laptob/hardware.nix`)
boot.kernelParams = [ "resume_offset=140544" ]; # Example value
```

If needed, switch (or compare) specific host `hardware.nix` with generated `/mnt/etc/nixos/hardware-configuration.nix`.

### Install NixOS.

In folder `/mnt/etc/nixos/antob`

```
# nixos-install --flake .#laptob
```

### Finalize

Reboot.

Change location of cloned config repo

```
$ sudo mv <location of cloned directory> <prefered location>
$ sudo chown -R <user>:users <new directory location>
```

Remove generated hardware config. This is done because in the past it would auto update this config if you would have auto update in your configuration.

```
$ sudo rm /etc/nixos/configuration.nix
```

Iterate on the config and rebuild system with

```
sudo nixos-rebuild switch --flake '.#laptob'
```
