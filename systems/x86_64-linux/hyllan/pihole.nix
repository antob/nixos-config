{ pkgs, lib, config, ... }:

with lib.antob;
let
  secrets = config.sops.secrets;
in
{
  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--privileged=true"
      ];
      environment = {
        TZ = "Europe/Stockholm";
        WEB_PORT = "8080";
        FTLCONF_LOCAL_IPV4 = "192.168.1.2";
        VIRTUAL_HOST = "pihole.lan";
        DNSMASQ_USER = "root";
      };
      environmentFiles = [ secrets.pihole_env_file.path ];
      volumes = [
        "/mnt/tank/docker/pihole/etc-pihole:/etc/pihole"
        "/mnt/tank/docker/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
    };
  };

  sops.secrets.pihole_env_file = { };

  services.nginx.virtualHosts = {
    "pihole.lan" = {
      serverAliases = [ "pihole" ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        extraConfig = ''
          proxy_buffering off;
          proxy_headers_hash_max_size 512;
          proxy_headers_hash_bucket_size 128; 
        '';
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 8080 ];
    allowedUDPPorts = [ 53 67 ];
  };

  services.resolved.enable = false;
}
