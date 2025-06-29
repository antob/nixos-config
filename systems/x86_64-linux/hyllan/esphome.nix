{ ... }:

let
  subdomain = "esphome";
  port = 6052;
  dataDir = "/mnt/tank/services/esphome";
in
{
  services = {
    esphome = {
      enable = true;
      address = "127.0.0.1";
      port = port;
      openFirewall = false;
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
      extraHandleConfig = ''
        basic_auth {
          admin {$ESPHOME_ADMIN_PASSWORD}
        }
      '';
    };
  };

  fileSystems = {
    "/var/lib/private/esphome" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 esphome esphome -"
  ];
}
