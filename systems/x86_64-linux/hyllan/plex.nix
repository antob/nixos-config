{ lib, ... }:

with lib.antob;
{
  fileSystems = {
    "/mnt/tank/plex" = {
      device = "zpool/plex";
      fsType = "zfs";
    };
  };

  services.plex = {
    enable = true;
    openFirewall = true;
    group = "media";
    dataDir = "/mnt/tank/plex";
  };

  services.nginx.virtualHosts = mkSslProxy "plex.antob.se" "http://127.0.0.1:32400";

  users.groups.media = { };
}
