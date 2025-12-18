{ config, ... }:

let
  subdomain = "monitor";
  port = 8090;
  dataDir = "/mnt/tank/services/beszel";
  secrets = config.sops.secrets;
in
{
  services = {
    beszel = {
      hub = {
        enable = true;
        port = port;
      };
      agent = {
        enable = true;
        environment = {
          HUB_URL = "https://monitor.antob.net";
          LISTEN = "45876";
        };
        environmentFile = secrets.beszel_agent_environment.path;
      };
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  fileSystems = {
    "/var/lib/private/beszel-hub" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 nobody nobody -"
  ];

  users.groups.beszel-agent = { };
  users.users.beszel-agent = {
    group = "beszel-agent";
    isSystemUser = true;
  };

  sops.secrets.beszel_agent_environment = {
    owner = "beszel-agent";
  };
}
