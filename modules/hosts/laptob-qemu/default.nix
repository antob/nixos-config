{ config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.laptob-qemu =
    {
      pkgs,
      lib,
      inputs,
      ...
    }:

    with lib;
    {
      imports = [
        inputs.nur.modules.nixos.default
        nixos.common
        nixos.desktop
      ];

      antob = {
        desktop.gnome = enabled;

        # persistence = enabled;

        virtualisation.docker.enable = false;
        virtualisation.podman.enable = false;
      };

      environment.systemPackages = with pkgs; [
        nfs-utils # Needed for mounting NFS shares
      ];

      services.tlp.enable = false;

      system.stateVersion = "22.11";
    };
}
