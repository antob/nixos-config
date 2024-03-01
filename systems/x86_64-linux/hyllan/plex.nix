{ lib, ... }:

with lib.antob;
{
  services.plex = {
    enable = true;
    openFirewall = true;
    group = "media";
    dataDir = "/mnt/tank/plex";
  };

  services.nginx.virtualHosts = mkSslProxy "plex.antob.se" "http://127.0.0.1:32400";

  users.groups.media = { };

  fileSystems = {
    "/mnt/tank/plex" = {
      device = "zpool/plex";
      fsType = "zfs";
    };
  };

  system.activationScripts.plex-chown.text = ''
    chown plex:plex /mnt/tank/plex
  '';
}
