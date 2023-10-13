{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.tools.flameshot;
in {
  options.antob.tools.flameshot = with types; {
    enable = mkEnableOption "Whether or not to install and configure flameshot.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      services.flameshot = {
        enable = true;
        settings = {
          General = {
            uiColor = "#61afef"; # One Dark Base 16 - base0D
            disabledTrayIcon = true;
          };
        };
      };

      xfconf.settings.xfce4-keyboard-shortcuts = mkIf config.antob.desktop.xfce-xmonad.enable {
        "commands/custom/Print" = "${pkgs.flameshot}/bin/flameshot gui";
      };
    };
  };
}
