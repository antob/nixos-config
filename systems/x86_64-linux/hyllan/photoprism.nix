{ config, lib, ... }:

with lib.antob;
let
  secrets = config.sops.secrets;
  siteDomain = "photos.antob.se";
  port = 2342;
in
{
  services = {
    photoprism = {
      enable = true;
      port = port;
      passwordFile = secrets.photoprism_admin_password.path;
      originalsPath = "/var/lib/private/photoprism/originals";
      address = "127.0.0.1";
      settings = {
        PHOTOPRISM_ADMIN_USER = "admin";
        PHOTOPRISM_DEFAULT_LOCALE = "en";
        PHOTOPRISM_DATABASE_DRIVER = "mysql";
        PHOTOPRISM_DATABASE_NAME = "photoprism";
        PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
        PHOTOPRISM_DATABASE_USER = "photoprism";
        PHOTOPRISM_SITE_URL = "https://${siteDomain}";
        PHOTOPRISM_SITE_TITLE = "PhotoPrism";
        # PHOTOPRISM_LOG_LEVEL = "trace";
      };
    };

    mysql = {
      ensureDatabases = [ "photoprism" ];
      ensureUsers = [{
        name = "photoprism";
        ensurePermissions = {
          "photoprism.*" = "ALL PRIVILEGES";
        };
      }];
    };

    nginx.virtualHosts = mkSslProxy siteDomain "http://127.0.0.1:${toString port}";
  };

  networking.firewall.allowedTCPPorts = [ port ];

  sops.secrets.photoprism_admin_password = { };

  fileSystems = {
    "/mnt/tank/photoprism" = {
      device = "zpool/photoprism";
      fsType = "zfs";
    };

    "/var/lib/private/photoprism" = {
      device = "/mnt/tank/photoprism";
      options = [ "bind" ];
    };
  };
}
