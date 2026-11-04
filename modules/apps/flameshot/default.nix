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
    let
      inherit (osConfig.lib.stylix) colors;
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
