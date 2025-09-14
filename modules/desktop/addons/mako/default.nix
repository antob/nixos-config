{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.mako;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.desktop.addons.mako = with types; {
    enable = mkEnableOption "Whether to enable mako.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.packages = [ pkgs.libnotify ];

      services.mako = {
        enable = true;
        settings = {
          anchor = "top-right";
          background-color = "#${colors.base10}d0";
          border-color = "#${colors.base0B}";
          text-color = "#${colors.base07}";
          border-size = 2;
          width = 420;
          height = 110;
          padding = 10;
          outer-margin = 20;
          default-timeout = 5000;
          max-icon-size = 32;
          border-radius = 4;
          font = "SFNS Display 12";
          # margin = 10;

          "mode=do-not-disturb" = {
            invisible = true;
          };

          "mode=do-not-disturb app-name=notify-send" = {
            invisible = false;
          };

          "urgency=critical" = {
            default-timeout = 0;
          };
        };
      };
    };
  };
}
