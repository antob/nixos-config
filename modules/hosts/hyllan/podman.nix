{ config, ... }:
{
  flake.modules.nixos.hyllan = {
    imports = [ config.aspects.nixos.podman ];
  };
}
