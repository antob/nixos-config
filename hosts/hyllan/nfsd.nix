{ ... }:

# Share needs ZFS managed mountpoint:
# $ sudo zfs create -o mountpoint=/mnt/tank/share/public zpool/public_share
#
# Set share property (WireGuard-only access over 10.64.1.0/24):
# $ sudo zfs set sharenfs="rw=10.64.1.0/24,all_squash" zpool/public_share
#
# Set owner (root is squashed to nobody:nogroup)
# $ sudo chown nobody:nogroup /mnt/tank/share/public
#
# Private share, WireGuard-only, restricted to desktob (10.64.1.6) and laptob-fw (10.64.1.7)
# $ sudo zfs create -o mountpoint=/mnt/tank/share/private -o encryption=on -o keyformat=raw -o keylocation=file:///run/secrets/zfs_encryption_key zpool/private_share
# $ sudo chown tob /mnt/tank/share/private
# $ sudo zfs set sharenfs="rw=10.64.1.6:10.64.1.7,root_squash" zpool/private_share
#
# Check exported shares:
# $ showmount -e <nfs-server>
#
# For some reason the datasets will be unavailable after boot.
# For now, set property `canmount` to `noauto` and manually mount
# the datasets after reboot:
# $ sudo zfs mount zpool/public_share
# $ sudo zfs mount zpool/private_share
# $ sudo zfs share -a

{
  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = "";
  };

  networking.firewall = {
    allowedTCPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
  };
}
