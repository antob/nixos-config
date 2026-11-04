{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.laptob-qemu =
    { pkgs, lib, ... }:

    with lib;
    {
      imports = [
        inputs.nur.modules.nixos.default
        nixos.common
        nixos.desktop
        nixos.avahi
        nixos.networking
        nixos.gnome
      ];

      antob = {

        # persistence = enabled;

      };

      environment.systemPackages = with pkgs; [
        nfs-utils # Needed for mounting NFS shares
      ];

      services.tlp.enable = false;

      system.stateVersion = "22.11";
    };

  flake.nixosConfigurations.laptob-qemu = inputs.nixpkgs.lib.nixosSystem {
    modules = [ nixos.laptob-qemu ];
  };
}
