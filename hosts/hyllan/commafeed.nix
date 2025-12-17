{ ... }:

let
  subdomain = "news";
  port = 8082;
  dataDir = "/mnt/tank/services/commafeed";
in
{
  services = {
    commafeed = {
      enable = true;
      environment = {
        COMMAFEED_USERS_STRICT_PASSWORD_POLICY = false;
      };
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  fileSystems = {
    "/var/lib/private/commafeed" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 nobody nobody -"
  ];
}
