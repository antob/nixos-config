{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.minimal-iso =
    { pkgs, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
        nixos.iso
      ];

      # Enable dconf to manage settings
      programs.dconf.enable = true;

      environment.systemPackages = with pkgs; [ parted ];
    };

  flake.nixosConfigurations.minimal-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ nixos.minimal-iso ];
  };
}
