{ ... }:

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

  users.groups.media = { };
}
