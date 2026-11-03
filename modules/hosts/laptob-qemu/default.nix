{ config, ... }:
let
  inherit (config.aspects) nixos;
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
        nixos.avahi
      ];

      antob = {
        desktop.gnome = enabled;

        # persistence = enabled;

      };

      environment.systemPackages = with pkgs; [
        nfs-utils # Needed for mounting NFS shares
      ];

      services.tlp.enable = false;

      system.stateVersion = "22.11";
    };
}
