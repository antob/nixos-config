{ pkgs, ... }:

let
  dataDir = "/mnt/tank/services/mysql";
in
{
  services.mysql = {
    enable = true;
    dataDir = dataDir;
    package = pkgs.mariadb;
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/mysql";
      fsType = "zfs";
    };
  };

  system.activationScripts.mysql-setup.text = ''
    chown myslq:mysql ${dataDir}
  '';
}
