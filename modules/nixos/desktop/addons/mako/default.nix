{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
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
        anchor = "top-right";
        backgroundColor = "#${colors.base10}d0";
        borderColor = "#${colors.base08}";
        textColor = "#${colors.base07}";
        borderSize = 2;
        borderRadius = 10;
        font = "SFNS Display 12";
        icons = true;
        layer = "overlay";
        margin = "10";
        padding = "15";
        maxIconSize = 48;
        maxVisible = 5;
        sort = "-time";
        defaultTimeout = 5000;
      };
    };

  };
}
