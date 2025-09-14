{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.hypridle;
in
{
  options.antob.desktop.addons.hypridle = with types; {
    enable = mkEnableOption "Whether to enable Hypridle.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "cmd-lock-screen"; # lock screen and 1password
            before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
            after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
            inhibit_sleep = 3; # wait until screen is locked
            ignore_dbus_inhibit = false;
            ignore_systemd_inhibit = false;
          };

          listener = [
            {
              timeout = 150; # 2.5 min
              on-timeout = "pidof hyprlock || cmd-launch-screensaver"; # start screensaver (if we haven't locked already)
            }
            {
              timeout = 300; # 5 min
              on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
            }
            {
              timeout = 330; # 5.5 min
              on-timeout = "hyprctl dispatch dpms off"; # screen off when timeout has passed
              on-resume = "hyprctl dispatch dpms on && brightnessctl -r"; # screen on when activity is detected
            }
          ];
        };
      };
    };
  };
}
