{ config, ... }:

let
  subdomain = "news";
  port = 8850;
  secrets = config.sops.secrets;
in
{
  services = {
    miniflux = {
      enable = true;
      adminCredentialsFile = secrets.miniflux_admin_credentials.path;
      config = {
        LISTEN_ADDR = "localhost:${toString port}";
        BASE_URL = "https://${subdomain}.antob.net";
      };
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  users.groups.miniflux = { };
  users.users.miniflux = {
    group = "miniflux";
    isSystemUser = true;
  };

  sops.secrets.miniflux_admin_credentials = {
    owner = "miniflux";
  };
}
