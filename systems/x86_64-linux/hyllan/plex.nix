{ ... }:

let
  dataDir = "/mnt/tank/services/plex";
  subdomain = "plex";
  port = 32400;
in
{
  services = {
    plex = {
      enable = true;
      openFirewall = true;
      group = "media";
      dataDir = dataDir;
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  networking.firewall.allowedTCPPorts = [ 32400 ];

  users.groups.media = { };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/plex";
      fsType = "zfs";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 plex media -"
  ];
}
