{
  config,
  ...
}:

let
  secrets = config.sops.secrets;
  dataDir = "/mnt/tank/services/docker/pihole";
  port = 8080;
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
        WEB_PORT = "${toString port}";
        FTLCONF_LOCAL_IPV4 = "192.168.1.2";
        VIRTUAL_HOST = "pihole.lan";
        DNSMASQ_USER = "root";
      };
      environmentFiles = [ secrets.pihole_env_file.path ];
      volumes = [
        "${dataDir}/etc-pihole:/etc/pihole"
        "${dataDir}/etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
    };
  };

  sops.secrets.pihole_env_file = { };

  services.nginx.virtualHosts = {
    "pihole.lan" = {
      serverAliases = [ "pihole" ];
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

  networking.firewall = {
    allowedTCPPorts = [
      53
      port
    ];
    allowedUDPPorts = [
      53
      67
    ];
  };

  services.resolved.enable = false;

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root -"
  ];
}
