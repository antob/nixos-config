{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.swayidle;
  niri = config.antob.desktop.niri.enable;
  hyprland = config.antob.desktop.hyprland.enable;
in
{
  options.antob.desktop.addons.swayidle = with types; {
    enable = mkEnableOption "Whether to enable Swayidle.";
    lockScreen = mkBoolOpt true "Whether to lock screen or just blank it.";
  };

  config = mkIf cfg.enable {
    antob.desktop.addons.swaylock.enable = cfg.lockScreen;

    antob.home.extraOptions = {
      services.swayidle = {
        enable = true;
        extraArgs = [
          "-w"
        ];
        events =
          optionals cfg.lockScreen [
            {
              event = "before-sleep";
              command = "${pkgs.swaylock}/bin/swaylock";
            }
            {
              event = "lock";
              command = "${pkgs.swaylock}/bin/swaylock";
            }
          ]
          ++ optionals niri [
            {
              event = "after-resume";
              command = "${pkgs.niri}/bin/niri msg action power-on-monitors && ${pkgs.brightnessctl}/bin/brightnessctl -r";
            }
          ]
          ++ optionals hyprland [
            {
              event = "resume";
              command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on && ${pkgs.brightnessctl}/bin/brightnessctl -r";
            }
          ];
        timeouts = [
          {
            timeout = 900;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ]
        ++ optionals (niri && cfg.lockScreen) [
          {
            timeout = 600;
            command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
          }
        ]
        ++ optionals (hyprland && cfg.lockScreen) [
          {
            timeout = 600;
            command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          }
        ]
        ++ optionals (niri && !cfg.lockScreen) [
          {
            timeout = 300;
            command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
          }
        ]
        ++ optionals (hyprland && !cfg.lockScreen) [
          {
            timeout = 300;
            command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          }
        ]
        ++ optionals cfg.lockScreen [
          {
            timeout = 300;
            command = "${pkgs.swaylock}/bin/swaylock -f";
          }
        ];
      };
    };
  };
}
