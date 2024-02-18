{ config, lib, ... }:

let
  cfg = config.antob.system.zfs;

  inherit (lib) mkEnableOption mkIf mkDefault;
  inherit (lib.antob) mkOpt enabled;
  inherit (lib.types) listOf str;
in
{
  options.antob.system.zfs = {
    enable = mkEnableOption "ZFS support";

    pools = mkOpt (listOf str) [ "rpool" ] "The ZFS pools to manage.";

    auto-snapshot = {
      enable = mkEnableOption "ZFS auto snapshotting";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      supportedFilesystems = [ "zfs" ];
      zfs.forceImportRoot = false;
    };

    services.zfs = {
      autoScrub = {
        enable = true;
        pools = cfg.pools;
      };

      autoSnapshot = mkIf cfg.auto-snapshot.enable {
        enable = true;
        flags = "-k -p --utc";
        weekly = mkDefault 3;
        daily = mkDefault 3;
        hourly = mkDefault 0;
        frequent = mkDefault 0;
        monthly = mkDefault 2;
      };
    };
  };
}
