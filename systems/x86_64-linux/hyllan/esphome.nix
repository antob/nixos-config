{ config, lib, ... }:

with lib.antob;
let
  secrets = config.sops.secrets;
  siteDomain = "esphome.lan";
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

    nginx.virtualHosts = {
      "${siteDomain}" = {
        basicAuthFile = secrets.esphome_admin_password.path;
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

  sops.secrets.esphome_admin_password = {
    owner = "nginx";
  };

  fileSystems = {
    "/var/lib/private/esphome" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  system.activationScripts.esphome-setup.text = ''
    mkdir -p ${dataDir}
  '';
}
