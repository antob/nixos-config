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
# $ sudo zfs create -o mountpoint=/mnt/tank/share/private zpool/private_share
# $ sudo chown tob /mnt/tank/share/private
# $ sudo chmod -R u=rwX,go= /mnt/tank/share/private
# $ sudo zfs set sharenfs="rw=10.64.1.6:10.64.1.7,root_squash" zpool/private_share
#
# Check exported shares:
# $ showmount -e <nfs-server>

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
