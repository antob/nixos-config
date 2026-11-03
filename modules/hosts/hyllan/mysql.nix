{
  flake.modules.nixos.hyllan =
    { pkgs, ... }:

    let
      dataDir = "/mnt/tank/services/mysql";
    in
    {
      services.mysql = {
        enable = true;
        inherit dataDir;
        package = pkgs.mariadb;
      };

      fileSystems = {
        "${dataDir}" = {
          device = "zpool/mysql";
          fsType = "zfs";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 mysql mysql -"
      ];
    };
}
