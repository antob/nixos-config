{ lib, ... }:

let
  siteDomain = "news.hyllan.lan";
  port = 8082;
  dataDir = "/mnt/tank/services/commafeed";
in
{
  services = {
    commafeed = {
      enable = true;
      stateDir = dataDir;
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

  systemd.services.commafeed.serviceConfig = {
    StateDirectory = lib.mkForce "state";
    WorkingDirectory = lib.mkForce dataDir;
    DynamicUser = lib.mkForce false;
  };

  users.groups.commafeed = { };
  users.users.commafeed = {
    group = "commafeed";
    isSystemUser = true;
  };

  system.activationScripts.commafeed-setup.text = ''
    mkdir -p ${dataDir}/state
    chown -R commafeed ${dataDir}
  '';
}
