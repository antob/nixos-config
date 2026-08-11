{ config, ... }:

let
  subdomain = "cp";
  port = 3923;
  dataDir = "/mnt/tank/services/copyparty";
  secrets = config.sops.secrets;
in
{
  services = {

    copyparty = {
      enable = true;
      # directly maps to values in the [global] section of the copyparty config.
      # see `copyparty --help` for available options
      settings = {
        i = "127.0.0.1";
        rproxy = -1;
      };

      # create users
      accounts = {
        admin.passwordFile = secrets.copyparty_admin_password.path;
      };

      volumes = {
        "/" = {
          # share the contents of "/srv/copyparty"
          path = "${dataDir}";
          # see `copyparty --help-accounts` for available options
          access = {
            # everyone gets read-access, but
            r = "*";
            # user "admin" get read-write
            rw = [
              "admin"
            ];
          };
          # see `copyparty --help-flags` for available options
          flags = {
            # "fk" enables filekeys (necessary for upget permission) (4 chars long)
            fk = 4;
            # scan for new files every 60sec
            scan = 60;
            # volflag "e2d" enables the uploads database
            # e2d = true;
            # "d2t" disables multimedia parsers (in case the uploads are malicious)
            # d2t = true;
            # skips hashing file contents if path matches *.iso
            nohash = "\.iso$";
          };
        };
      };
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  sops.secrets.copyparty_admin_password = {
    owner = "copyparty";
  };

  fileSystems = {
    "/var/lib/private/copyparty" = {
      device = dataDir;
      fsType = "none";
      options = [ "bind" ];
    };
  };
}
