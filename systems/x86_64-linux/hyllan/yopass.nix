{ pkgs, lib, ... }:

with lib.antob;
{
  virtualisation.oci-containers.containers = {
    yopass = {
      image = "jhaals/yopass";
      autoStart = true;
      extraOptions = [ "--network=host" ];
      cmd = [ "--memcached=127.0.0.1:11211" "--port=8090" ];
    };
  };

  services = {
    memcached.enable = true;
    nginx.virtualHosts = mkSslProxy "secrets.antob.se" "http://127.0.0.1:8090";
  };
}
