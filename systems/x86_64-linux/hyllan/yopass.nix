{ pkgs, lib, ... }:

with lib.antob;
let
  siteDomain = "secrets.antob.se";
  port = 8090;
in
{
  virtualisation.oci-containers.containers = {
    yopass = {
      image = "jhaals/yopass";
      autoStart = true;
      extraOptions = [ "--network=host" ];
      cmd = [
        "--memcached=127.0.0.1:11211"
        "--port=${toString port}"
        "--max-length 500000"
      ];
    };
  };

  services = {
    memcached.enable = true;
    nginx.virtualHosts = mkSslProxy siteDomain "http://127.0.0.1:${toString port}";
  };
}
