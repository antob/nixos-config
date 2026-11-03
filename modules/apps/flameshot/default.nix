{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.flameshot =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    let
      flameshot-gui = pkgs.callPackage ./_files/flameshot-gui.nix { };
    in
    {
      config = {
        home-manager.sharedModules = [ homeManager.flameshot ];

        environment.systemPackages = [ flameshot-gui ];

      };
    };

  flake.modules.homeManager.flameshot =
    { osConfig, lib, ... }:
    with lib;
    let
      colors = osConfig.antob.color-scheme.colors;
    in
    {
      services.flameshot = {
        enable = true;
        settings = {
          General = {
            uiColor = "#${colors.base0C}";
            disabledTrayIcon = true;
          };
        };
      };
    };

}
