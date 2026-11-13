{
  flake.modules.nixos.hyllan =
    { config, ... }:

    let
      subdomain = "news";
      port = 8851;
      dataDir = "/mnt/tank/services/freshrss";
      inherit (config.sops) secrets;
    in
    {
      services = {
        freshrss = {
          enable = true;
          inherit dataDir;
          baseUrl = "https://${subdomain}.antob.net";
          defaultUser = "admin";
          passwordFile = secrets.freshrss_password.path;
          webserver = "caddy";
          # Loopback-only site matching any Host, since the proxy forwards Host: news.antob.net.
          virtualHost = "http://:${toString port}";
          api.enable = true;
        };

        caddy = {
          virtualHosts.${config.services.freshrss.virtualHost}.extraConfig = ''
            bind 127.0.0.1
          '';

          antobProxies."${subdomain}" = {
            hostName = "127.0.0.1";
            inherit port;
          };
        };
      };

      sops.secrets.freshrss_password = {
        owner = config.services.freshrss.user;
      };
    };
}
