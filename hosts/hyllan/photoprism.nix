{ config, ... }:

let
  secrets = config.sops.secrets;
  subdomain = "photos";
  port = 2342;
  dataDir = "/mnt/tank/services/photoprism";
in
{
  services = {
    photoprism = {
      enable = true;
      port = port;
      passwordFile = secrets.photoprism_admin_password.path;
      originalsPath = "/var/lib/private/photoprism/originals";
      importPath = "/var/lib/private/photoprism/import";
      address = "127.0.0.1";
      settings = {
        PHOTOPRISM_ADMIN_USER = "admin";
        PHOTOPRISM_DEFAULT_LOCALE = "en";
        PHOTOPRISM_DATABASE_DRIVER = "mysql";
        PHOTOPRISM_DATABASE_NAME = "photoprism";
        PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
        PHOTOPRISM_DATABASE_USER = "photoprism";
        PHOTOPRISM_SITE_URL = "https://${subdomain}.antob.net";
        PHOTOPRISM_SITE_TITLE = "PhotoPrism";
        # PHOTOPRISM_LOG_LEVEL = "trace";
      };
    };

    mysql = {
      ensureDatabases = [ "photoprism" ];
      ensureUsers = [
        {
          name = "photoprism";
          ensurePermissions = {
            "photoprism.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];

  sops.secrets.photoprism_admin_password = { };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/photoprism";
      fsType = "zfs";
    };

    "/var/lib/private/photoprism" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 photoprism photoprism -"
  ];
}
