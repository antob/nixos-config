{ ... }:

# NFS exports are declared declaratively below and written to /etc/exports by
# NixOS (services.nfs.server.exports). The ZFS `sharenfs` property is left
# unset/off on all share datasets so ZFS does not manage or double-register
# exports.
#
# To add a new share:
#   1. Create the dataset with mountpoint=legacy (not a real path):
#        $ sudo zfs create -o mountpoint=legacy -o canmount=on zpool/<name>_share
#   2. Set ownership/permissions on the mountpoint directory once it's
#      mounted via the fileSystems entry below, e.g.:
#        $ sudo chown nobody:nogroup /mnt/tank/share/<name>
#      or for a restricted share:
#        $ sudo chown -R tob:tob /mnt/tank/share/<name>
#        $ sudo chmod -R u=rwX,go= /mnt/tank/share/<name>
#   3. Add a `fileSystems."/mnt/tank/share/<name>" = { device = "zpool/<name>_share"; fsType = "zfs"; };`
#      entry below. Its mountpoint path must be nested under /mnt/tank, which
#      is what makes systemd infer After=mnt-tank.mount/RequiresMountsFor
#      automatically and mount it in the correct order.
#   4. Add a matching entry under `services.nfs.server.exports` below.
#   5. Confirm sharenfs stays off on the new dataset:
#        $ sudo zfs set sharenfs=off zpool/<name>_share
#   6. Rebuild/deploy/reboot, then verify:
#        $ showmount -e <nfs-server>
#        $ ls /mnt/tank/share/<name>

{
  fileSystems = {
    "/mnt/tank/share/public" = {
      device = "zpool/public_share";
      fsType = "zfs";
    };
    "/mnt/tank/share/private" = {
      device = "zpool/private_share";
      fsType = "zfs";
    };
  };

  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = "";
    exports = {
      "/mnt/tank/share/public" = {
        "10.64.1.0/24" = [
          "rw"
          "all_squash"
          "no_subtree_check"
        ];
      };
      "/mnt/tank/share/private" = {
        "10.64.1.6" = [
          "rw"
          "root_squash"
          "no_subtree_check"
        ];
        "10.64.1.7" = [
          "rw"
          "root_squash"
          "no_subtree_check"
        ];
      };
    };
  };

  # Register exports only after the ZFS datasets are mounted; otherwise
  # `exportfs -r` at nfs-server start can drop the exports on boot.
  systemd.services.nfs-server = {
    wants = [ "zfs-mount.service" ];
    after = [ "zfs-mount.service" ];
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
