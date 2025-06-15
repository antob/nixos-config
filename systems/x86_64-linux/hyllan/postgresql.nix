{ config, pkgs, ... }:

let
  dataDir = "/mnt/tank/services/postgresql";
in
{
  # Create postgres user and group before enabling the service
  # to be able to set the correct ownership of the data directory.
  users = {
    users.postgres = {
      name = "postgres";
      uid = config.ids.uids.postgres;
      group = "postgres";
      description = "PostgreSQL server user";
      home = dataDir;
      useDefaultShell = true;
    };

    groups.postgres.gid = config.ids.gids.postgres;
  };

  services.postgresql = {
    enable = true;
    dataDir = dataDir;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/postgresql";
      fsType = "zfs";
    };
  };
}
