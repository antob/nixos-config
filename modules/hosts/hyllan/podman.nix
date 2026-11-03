{ config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.hyllan =
    { lib, ... }:

    with lib;
    let
      dataDir = "/mnt/tank/services/docker";
    in
    {
      imports = [ nixos.podman ];

      fileSystems = {
        "${dataDir}" = {
          device = "zpool/docker";
          fsType = "zfs";
        };
      };
    };
}
