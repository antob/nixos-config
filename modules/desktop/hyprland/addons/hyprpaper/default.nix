{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.antob.desktop.hyprland;
  hypr-pkgs = inputs.hyprnix.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  config = lib.mkIf cfg.enable {
    antob.home.extraOptions.programs.hyprpaper = {
      enable = true;
      package = hypr-pkgs.hyprpaper;
      settings = {
        splash = false;

        wallpaper = [
          {
            # monitor = "DP-3";
            path = "home/tob/Pictures/Wallpapers/Omarchy-Backgrounds/1-scenery-pink-lakeside-sunset-lake-landscape-scenic-panorama-7680x3215-144.png";
            # fit_mode = "tile";
          }
        ];
      };
    };
  };
}
