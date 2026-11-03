{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.apps.flameshot;
  flameshot-gui = pkgs.callPackage ./flameshot-gui.nix { };
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.apps.flameshot = with types; {
    enable = mkEnableOption "Whether or not to install and configure flameshot.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ flameshot-gui ];

    antob.home.extraOptions = {
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
  };
}
