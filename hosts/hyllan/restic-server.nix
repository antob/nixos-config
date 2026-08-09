{
  config,
  lib,
  ...
}:
let
  secrets = config.sops.secrets;
  dataDir = "/mnt/tank/services/restic-server";

  mkResticBackups =
    names:
    lib.genAttrs names (name: {
      repository = "${dataDir}/${name}";
      passwordFile = secrets.restic_client_backup_password.path;
      paths = null;
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      timerConfig = {
        OnCalendar = "02:30";
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
    });
in
{
  # Restic REST server for laptop backups, reachable over the WireGuard
  # tunnel only (port is opened on the wg0 interface alone).
  services.restic.server = {
    enable = true;
    dataDir = dataDir;
    listenAddress = "8000";
    extraFlags = [ "--no-auth" ];
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 8000 ];

  # Retention backup repos runs server-side. Jobs are prune-only (paths = null).
  services.restic.backups = mkResticBackups [ "desktob" ];

  sops.secrets.restic_client_backup_password = {
    sopsFile = ../common/secrets.yaml;
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/restic-server";
      fsType = "zfs";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root -"
  ];
}
