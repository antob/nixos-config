{ inputs, config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules = {
    nixos.install-iso =
      { pkgs, modulesPath, ... }:
      {
        imports = [
          (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
          inputs.nur.modules.nixos.default
          nixos.iso
          nixos.audio
          nixos.printing
          nixos.vscode
          nixos.firefox
          nixos.gnome
        ];

        home-manager.sharedModules = [ homeManager.install-iso ];

        environment.systemPackages = with pkgs; [
          ungoogled-chromium
          gnome-calculator
          gparted
        ];
      };

    homeManager.install-iso = {
      programs.bat = {
        enable = true;
        config.theme = "catppuccin";
        themes = {
          catppuccin = {
            src = builtins.fetchurl {
              url = "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme";
              sha256 = "sha256:0xxashmrrj81y99ia4hvcpmplkzr1rlpgh4idf9inc7bikq6cm9r";
              name = "catppuccin.tmTheme";
            };
          };
        };
      };
    };
  };

  flake.nixosConfigurations.install-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ nixos.install-iso ];
  };
}
