{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = config.sops.secrets;
  dataDir = "/mnt/tank/services/restic-server";
  pruneOpts = [
    "--keep-daily 7"
    "--keep-weekly 4"
    "--keep-monthly 12"
  ];
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

  # Retention prune for all repos in the server dataDir. Runs as the restic
  # user so files written by prune stay readable by the rest server.
  systemd.services.restic-prune-all-client-backups = {
    description = "Prune retention for all restic client backup repositories";
    serviceConfig = {
      Type = "oneshot";
      User = "restic";
      Group = "restic";
      CacheDirectory = "restic-prune-all";
      CacheDirectoryMode = "0700";
    };
    unitConfig.RequiresMountsFor = [ dataDir ];
    environment.RESTIC_CACHE_DIR = "/var/cache/restic-prune-all";
    path = [
      pkgs.restic
      pkgs.coreutils
    ];
    script = ''
      set -u
      failed=0
      for repo in ${dataDir}/*; do
        [ -d "$repo" ] || continue
        [ -f "$repo/config" ] || continue
        name="$(basename "$repo")"
        echo "=== Pruning $name"
        if ! restic -r "$repo" --password-file ${secrets.restic_client_backup_password.path} \
            forget --prune ${lib.concatStringsSep " " pruneOpts}; then
          echo "Pruning $name failed" >&2
          failed=1
        fi
      done
      exit "$failed"
    '';
  };

  systemd.timers.restic-prune-all-client-backups = {
    description = "Daily restic client backups pruning";
    timerConfig = {
      OnCalendar = "02:30";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  sops.secrets.restic_client_backup_password = {
    sopsFile = ../common/secrets.yaml;
    owner = "restic";
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
