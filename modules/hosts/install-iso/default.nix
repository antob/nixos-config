{ inputs, config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules = {
    nixos.install-iso =
      { pkgs, modulesPath, ... }:
      {
        imports = with nixos; [
          (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
          inputs.nur.modules.nixos.default
          iso
          audio
          printing
          vscode
          firefox
          gnome
        ];

        home-manager.sharedModules = [ homeManager.install-iso ];

        environment.systemPackages = with pkgs; [
          ungoogled-chromium
          gnome-calculator
          gparted
        ];
      };

    homeManager.install-iso = {
      programs.bat.enable = true;
      stylix.targets.bat.enable = true;
    };
  };

  flake.nixosConfigurations.install-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ nixos.install-iso ];
  };
}
