{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.addons.swaylock;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.desktop.addons.swaylock = with types; {
    enable = mkEnableOption "Whether to enable swaylock.";
  };

  config = mkIf cfg.enable {
    security.pam.services.swaylock = { };

    antob.home.extraOptions = {
      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
        settings = {
          image = "${./lock-background.png}";
          clock = true;
          font = "SFNS Display 12";
          timestr = "%R";
          datestr = "%a, %e of %B";
          indicator = true;
          indicator-radius = 100;
          indicator-thickness = 6;
          effect-blur = "7x5";
          effect-vignette = "0.5:0.5";
          grace = 2;
          fade-in = 1.0;

          key-hl-color = "00000066";
          separator-color = "00000000";

          inside-color = "00000033";
          inside-clear-color = "ffffff00";
          inside-caps-lock-color = "ffffff00";
          inside-ver-color = "ffffff00";
          inside-wrong-color = "ffffff00";

          ring-color = "ffffff";
          ring-clear-color = "ffffff";
          ring-caps-lock-color = "ffffff";
          ring-ver-color = "ffffff";
          ring-wrong-color = "ffffff";

          line-color = "00000000";
          line-clear-color = "ffffffFF";
          line-caps-lock-color = "ffffffFF";
          line-ver-color = "ffffffFF";
          line-wrong-color = "ffffffFF";

          text-color = "ffffff";
          text-clear-color = "ffffff";
          text-ver-color = "ffffff";
          text-wrong-color = "ffffff";

          bs-hl-color = "ffffff";
        };
      };
    };
  };
}
