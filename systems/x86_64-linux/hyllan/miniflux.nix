{ config, ... }:

let
  siteDomain = "news.hyllan.lan";
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
        BASE_URL = "http://${siteDomain}";
      };
    };

    nginx.virtualHosts = {
      "${siteDomain}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          extraConfig = ''
            proxy_buffering off;
            proxy_headers_hash_max_size 512;
            proxy_headers_hash_bucket_size 128; 
          '';
        };
      };
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
