{ config, ... }:
let
  secrets = config.sops.secrets;
  port = 2342;
in
{
  services = {
    photoprism = {
      enable = true;
      port = port;
      passwordFile = secrets.photoprism_admin_password.path;
      originalsPath = "/var/lib/private/photoprism/originals";
      address = "0.0.0.0";
      settings = {
        PHOTOPRISM_ADMIN_USER = "admin";
        PHOTOPRISM_DEFAULT_LOCALE = "en";
        PHOTOPRISM_DATABASE_DRIVER = "mysql";
        PHOTOPRISM_DATABASE_NAME = "photoprism";
        PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
        PHOTOPRISM_DATABASE_USER = "photoprism";
        # PHOTOPRISM_SITE_URL = "http://sub.domain.tld:2342";
        PHOTOPRISM_SITE_TITLE = "PhotoPrism";
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
  };

  networking.firewall.allowedTCPPorts = [ port ];

  # Sops secrets
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
