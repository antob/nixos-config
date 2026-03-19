{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.hypridle;
  cmd-launch-blankscreen = lib.getExe (pkgs.callPackage ../../scripts/cmd-launch-blankscreen.nix { });
in
{
  options.antob.desktop.addons.hypridle = with types; {
    enable = mkEnableOption "Whether to enable Hypridle.";
    lockScreen = mkBoolOpt true "Whether to lock screen or just blank it.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      services.hypridle = {
        enable = true;
        package = inputs.hyprnix.packages.${pkgs.stdenv.hostPlatform.system}.hypridle;
        settings = {
          general = {
            lock_cmd = "cmd-lock-screen"; # lock screen when idle
            before_sleep_cmd = mkIf cfg.lockScreen "loginctl lock-session"; # lock before suspend.
            after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
            inhibit_sleep = mkIf cfg.lockScreen 3; # wait until screen is locked
            ignore_dbus_inhibit = false;
            ignore_systemd_inhibit = false;
          };

          listener = [
            {
              timeout = 150; # 2.5 min
              on-timeout =
                if cfg.lockScreen then "pidof hyprlock || cmd-launch-screensaver" else "${cmd-launch-blankscreen}";
            }
            {
              timeout = 330; # 5.5 min
              on-timeout = "hyprctl dispatch dpms off"; # screen off when timeout has passed
              on-resume = "hyprctl dispatch dpms on && brightnessctl -r"; # screen on when activity is detected
            }
            {
              timeout = 600; # 10 min
              on-timeout = "systemctl suspend"; # Suspend computer
            }
          ]
          ++ optionals cfg.lockScreen [
            {
              timeout = 300; # 5 min
              on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
            }
          ];
        };
      };
    };
  };
}
