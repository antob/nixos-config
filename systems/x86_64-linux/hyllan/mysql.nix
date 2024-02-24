{ pkgs, ... }:

{
  services.mysql = {
    enable = true;
    dataDir = "/mnt/tank/mysql";
    package = pkgs.mariadb;
  };

  fileSystems = {
    "/mnt/tank/mysql" = {
      device = "zpool/mysql";
      fsType = "zfs";
    };
  };
}
