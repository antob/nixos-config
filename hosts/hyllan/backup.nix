{
  config,
  pkgs,
  lib,
  ...
}:

let
  secrets = config.sops.secrets;
  baseMountPoint = "/mnt/restic-snapshot";
  baseRepo = "s3:hel1.your-objectstorage.com/antob-hyllan-backups";

  mkResticBackup =
    {
      dataset,
      paths ? [ "" ],
      excludes ? [ ],
    }:
    {
      initialize = true;
      environmentFile = secrets.restic_env_file.path;
      repository = "${baseRepo}/${dataset}";

      paths = map (path: "${baseMountPoint}/${dataset}${path}") paths;
      exclude = map (exclude: "${baseMountPoint}/${dataset}${exclude}") excludes;

      backupPrepareCommand = ''
        ${pkgs.zfs}/bin/zfs snapshot zpool/${dataset}@restic-backup
        mkdir -p ${baseMountPoint}/${dataset}
        ${pkgs.util-linux}/bin/mount -t zfs zpool/${dataset}@restic-backup ${baseMountPoint}/${dataset}
      '';

      backupCleanupCommand = ''
        ${pkgs.util-linux}/bin/umount ${baseMountPoint}/${dataset}
        ${pkgs.zfs}/bin/zfs destroy zpool/${dataset}@restic-backup
        rmdir ${baseMountPoint}/${dataset}
      '';

      timerConfig = {
        OnCalendar = "01:05";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
    };
in
{
  services.restic.backups = {
    hass = mkResticBackup {
      dataset = "hass";
    };

    photoprism = mkResticBackup {
      dataset = "photoprism";
    };

    mysql = mkResticBackup {
      dataset = "mysql";
    };

    postgresql = mkResticBackup {
      dataset = "postgresql";
    };

    public_share = mkResticBackup {
      dataset = "public_share";
    };

    private_share = mkResticBackup {
      dataset = "private_share";
    };

    syncthing = mkResticBackup {
      dataset = "syncthing";
      excludes = [
        "/services/syncthing/Projects"
      ];
    };

    tank = mkResticBackup {
      dataset = "tank";
      paths = [
        "/services/vaultwarden"
        "/services/mass"
        "/services/caddy"
        "/services/esphome"
      ];
    };
  };

  # The restic module hardcodes PrivateTmp=true, which hides the ZFS mount
  # from ExecStart. Disable it so the snapshot mount survives into the backup.
  systemd.services =
    lib.genAttrs (map (name: "restic-backups-${name}") (lib.attrNames config.services.restic.backups))
      (name: {
        serviceConfig.PrivateTmp = lib.mkForce false;
      });

  sops.secrets.restic_env_file = { };
}
