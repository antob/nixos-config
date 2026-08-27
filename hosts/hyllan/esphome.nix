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
    "/var/lib/esphome" = {
      device = dataDir;
      fsType = "none";
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 esphome esphome -"
  ];

  # mDNS so the dashboard can discover devices by name on the LAN.
  networking.firewall.allowedUDPPorts = [ 5353 ];
}
