{ ... }:

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
      ];
    };
  };

  services = {
    memcached.enable = true;
    caddy.virtualHosts."${siteDomain}".extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };
}
