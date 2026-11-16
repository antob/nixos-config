{
  flake.modules.nixos.hyllan =
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
        # TODO: postgresql_14 is EOL and removed from unstable; pg_upgrade to a newer major.
        package = pkgs.stable.postgresql_14;
        inherit dataDir;
      };

      fileSystems = {
        "${dataDir}" = {
          device = "zpool/postgresql";
          fsType = "zfs";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0700 postgres postgres -"
      ];
    };
}
