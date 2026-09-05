{ lib, ... }:

with lib;
let
  dataDir = "/mnt/tank/services/docker";
in
{
  antob = {
    virtualisation.podman.enable = true;
    virtualisation.docker.enable = mkForce false;
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/docker";
      fsType = "zfs";
    };
  };
}
