{ lib, ... }:

with lib.antob;
let
  dataDir = "/mnt/tank/services/plex";
  siteDomain = "plex.antob.se";
in
{
  services.plex = {
    enable = true;
    openFirewall = true;
    group = "media";
    dataDir = dataDir;
  };

  services.nginx.virtualHosts = mkSslProxy siteDomain "http://127.0.0.1:32400";
  networking.firewall.allowedTCPPorts = [ 32400 ];

  users.groups.media = { };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/plex";
      fsType = "zfs";
    };
  };

  system.activationScripts.plex-setup.text = ''
    chown plex:media ${dataDir}
  '';
}
