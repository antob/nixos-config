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
  wpFolder = "~/Pictures/Wallpapers";
  wp1 = "${wpFolder}/Omarchy-Backgrounds/3-Milad-Fakurian-Abstract-Purple-Blue.jpg";
in
{
  config = lib.mkIf cfg.enable {
    antob.home.extraOptions.services.hyprpaper = {
      enable = true;
      package = hypr-pkgs.hyprpaper;
      settings = {
        splash = false;

        wallpaper = [
          {
            monitor = "";
            path = "${wp1}";
          }
          {
            monitor = "eDP-1";
            path = "${wp1}";
          }
          {
            monitor = "DP-4";
            path = "${wp1}";
          }
        ];
      };
    };
  };
}
