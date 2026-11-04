# My NixOS configuration

A flake for all my machines: desktops, a laptop, a home server, a public server and
a few Raspberry Pis. It follows the [dendritic pattern](https://github.com/mightyiam/dendritic):

- every `.nix` file under `modules/` is a [flake-parts](https://flake.parts) module,
  loaded automatically by [import-tree](https://github.com/vic/import-tree)
- each feature is an **aspect** (`flake.modules.nixos.<name>`, plus a Home Manager half
  in `flake.modules.homeManager.<name>` when it configures the user), and a host turns
  a feature on by importing it
- hosts import one **profile** that bundles the features they share; profiles are
  layered, each including the one before it (`workstation` ⊃ `common` ⊃ `server` ⊃ `shell`)

Other building blocks: [Home Manager](https://github.com/nix-community/home-manager)
(NixOS-integrated), [disko](https://github.com/nix-community/disko) for disk layouts,
[sops-nix](https://github.com/Mic92/sops-nix) for secrets,
[preservation](https://github.com/nix-community/preservation) for an ephemeral root, and
[nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) for the Pis.

## Hosts

| Host                          | Machine          | Profile       | Notes                                                |
| ----------------------------- | ---------------- | ------------- | ---------------------------------------------------- |
| `desktob`                     | Desktop (AMD)    | `workstation` | Hyprland, gaming, local LLMs, impermanence           |
| `laptob`                      | Framework laptop | `workstation` | Hyprland, fingerprint, secure boot, impermanence     |
| `hyllan`                      | Home server      | `common`      | ZFS `tank`, self-hosted services, nix cache, backups |
| `wiggum`                      | Public server    | `server`      | Caddy, fail2ban, WireGuard hub                       |
| `pihole`                      | Raspberry Pi 4   | `rpi`         | Pi-hole DNS                                          |
| `pikvm`                       | Raspberry Pi     | `rpi`         | PiKVM (KVM over IP)                                  |
| `pidesk`                      | Raspberry Pi 4   | `rpi`         | Desk helper (e.g. wakes `desktob`)                   |
| `laptob-qemu`                 | VM               | `common`      | GNOME test machine                                   |
| `install-iso` / `minimal-iso` | Installer images | `iso`         | Graphical (GNOME) / minimal installer                |
| `rpi4-installer`              | SD image         | –             | Bootstrap image for a new Pi 4                       |

## Layout

```text
flake.nix         inputs only; outputs = import-tree ./modules
modules/
  flake/          flake-parts plumbing: systems, flake.lib, overlays, packages
  base/           imported by every host: nix, Home Manager, user, sops, disko, …
  profiles/       shell, server, common, workstation, iso, rpi, desktop, laptop, gaming
  hosts/<host>/   one folder per machine (+ hosts/common/ for shared secrets)
  shell/ terminals/ editors/ dev/ ai/ network/ desktop/ apps/ hardware/
  services/ system/   one aspect per feature, grouped by role
pkgs/             custom packages, available as pkgs.<name>
justfile          day-to-day commands
```

Folders only group files for humans; every aspect name is unique repo-wide, so a
file can move without changing anything. [`AGENTS.md`](AGENTS.md) documents the
conventions (aspect file shape, options, Home Manager halves, ordering) in detail.

### Adding things

- **A feature:** create `modules/<group>/<name>.nix` defining
  `flake.modules.nixos.<name>` (and `flake.modules.homeManager.<name>` if needed).
  Import it as `nixos.<name>` from a profile or host. New files must be tracked by
  git before Nix sees them (`git add -N <file>`).
- **A host:** create `modules/hosts/<host>/default.nix` that defines
  `flake.modules.nixos.<host>` (importing a profile) and
  `flake.nixosConfigurations.<host>`. Put `hardware.nix`, `disk-config.nix` and
  `secrets.yaml` next to it; they add to the same aspect automatically.

## Everyday use

Commands go through [`just`](https://github.com/casey/just); run `just` for the full list.

| Command                                 | What it does                                      |
| --------------------------------------- | ------------------------------------------------- |
| `just build [host]`                     | Build the current (or named) host                 |
| `just switch [host]`                    | Build and activate                                |
| `just test [host]` / `just boot [host]` | Activate without a boot entry / on next boot      |
| `just deploy <mode> <host>`             | `nixos-rebuild <mode>` on `<host>.lan` over SSH   |
| `just fmt`                              | Format all Nix files                              |
| `just history` / `just clean`           | List generations / remove those older than 7 days |

Updating, using the inputs hyllan's nightly cache already built (full cache hits):

```sh
just bump-prev && just up-cached && just build
just switch
# then commit flake.nix + flake.lock together
```

`just up` / `just upp <input>` update all inputs or a single one. Packages from the
other channels are available as `pkgs.stable.<pkg>`, `pkgs.next.<pkg>` and
`pkgs.prev.<pkg>` (the previous nixpkgs pin, handy when an update breaks something).

## Secrets

Secrets are sops-encrypted YAML: `modules/hosts/<host>/secrets.yaml` per host and
`modules/hosts/common/secrets.yaml` for shared ones. Hosts decrypt them with their SSH
host key converted to PGP. To add a host's key:

```sh
nix shell nixpkgs#ssh-to-pgp
ssh <host>.lan "sudo cat /etc/ssh/ssh_host_rsa_key" \
  | ssh-to-pgp -o modules/hosts/<host>/public_key.asc -name <host> -email tob@<host> -comment "Host key for <host>"
# add the printed fingerprint to .sops.yaml (keys + creation_rules), then:
gpg --import modules/hosts/<host>/public_key.asc
sops updatekeys modules/hosts/common/secrets.yaml
```

## Installation

Hosts with a `disk-config.nix` (desktob, laptob, hyllan, wiggum, laptob-qemu) get
partitioned and formatted by disko. desktob and laptob use GPT with a 1 GiB EFI
partition, then LUKS2 with btrfs subvolumes `@root`, `@nix`, `@persist` and `@swap`,
plus an `@root-blank` snapshot that root is rolled back to on every boot
(impermanence). The other hosts' layouts are in their `disk-config.nix`.

### Installer media

```sh
just iso            # graphical installer (install-iso)
just iso minimal    # minimal installer
just build-sd-image pihole   # SD image for a Raspberry Pi host
```

### Install over SSH (nixos-anywhere)

Boot the target from an installer ISO, make sure you can SSH in as root, then from
this repo:

```sh
just install <host> root@<ip>
```

### Install locally (disko-install)

From the booted installer on the target machine:

```sh
nix shell nixpkgs#git
git clone https://github.com/antob/nixos-config && cd nixos-config
sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake .#<host> --disk main /dev/nvme0n1
```

### After installing

- **Hibernation (laptob):** the swapfile's `resume_offset` is set in
  `modules/hosts/laptob/hardware.nix`. If the disk or the swapfile size changed,
  recalculate it and rebuild:

  ```sh
  sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
  ```

- **Hardware config:** compare the host's `hardware.nix` with the output of
  `nixos-generate-config --show-hardware-config` and adjust if needed.
- **Secrets:** add the new host key as described under [Secrets](#secrets).
- Move the cloned repo to its usual place, `chown` it to your user, and from then
  on use `just switch`.

### ZFS pool (hyllan)

The data pool is created by hand and mounted by NixOS:

```sh
sudo zpool create -O compression=on -O mountpoint=none -O acltype=posixacl -O xattr=sa -o ashift=12 \
  tank raidz ata-TOSHIBA_HDWG440_14A0A017FZ0G ata-TOSHIBA_HDWG440_14A0A024FZ0G \
  ata-TOSHIBA_HDWG440_Z3B0A06DFZ0G ata-TOSHIBA_HDWG440_Z3B0A0FLFZ0G

# Let NixOS manage mounting datasets
sudo zfs set mountpoint=legacy tank

# Reservation: ZFS is copy-on-write and can't delete files once completely full
sudo zfs create -o refreservation=1G -o mountpoint=none tank/reserve
```

### Manual partitioning (without disko)

The original hand-made layout: an encrypted btrfs system with a separate `@home`
subvolume and no impermanence rollback. Prefer disko where a `disk-config.nix` exists.

```sh
# Optional: clear old partition tables
sgdisk --zap-all /dev/<drive>

# 1 GiB EFI partition + the rest for the encrypted system
sgdisk --clear --new=1:0:+1GiB --typecode=1:ef00 --change-name=1:EFI \
  --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsystem /dev/<drive>

cryptsetup luksFormat --type luks2 --align-payload=8192 -s 256 -c aes-xts-plain64 /dev/disk/by-partlabel/cryptsystem
cryptsetup open /dev/disk/by-partlabel/cryptsystem system

mkfs.btrfs --label system /dev/mapper/system
mount -t btrfs LABEL=system /mnt
for sv in @root @home @nix @persist @swap; do btrfs subvolume create /mnt/$sv; done
umount -R /mnt

opts=defaults,x-mount.mkdir,compress=zstd,ssd,noatime
mount -t btrfs -o $opts,subvol=@root    LABEL=system /mnt
mount -t btrfs -o $opts,subvol=@home    LABEL=system /mnt/home
mount -t btrfs -o $opts,subvol=@nix     LABEL=system /mnt/nix
mount -t btrfs -o $opts,subvol=@persist LABEL=system /mnt/persist
# no compression on the swap subvolume
mount -t btrfs -o defaults,x-mount.mkdir,compress=none,ssd,noatime,subvol=@swap LABEL=system /mnt/.swapvol

mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
mount -o x-mount.mkdir LABEL=EFI /mnt/efi

# Swapfile: RAM + 2 GB is a good size (needs btrfs-progs >= 6.1)
btrfs filesystem mkswapfile --size 10G /mnt/.swapvol/swapfile
btrfs inspect-internal map-swapfile -r /mnt/.swapvol/swapfile   # -> resume_offset
swapon /mnt/.swapvol/swapfile

nixos-install --flake .#<host>
```
