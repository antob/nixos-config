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
  mango = config.antob.desktop.mango.enable;
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
        events = {
          "before-sleep" = mkIf cfg.lockScreen "${pkgs.swaylock}/bin/swaylock";
          "lock" = mkIf cfg.lockScreen "${pkgs.swaylock}/bin/swaylock";
          "after-resume" =
            if mango then
              "${pkgs.wlr-dpms}/bin/wlr-dpms on && ${pkgs.brightnessctl}/bin/brightnessctl -r"
            else if niri then
              "${pkgs.niri}/bin/niri msg action power-on-monitors && ${pkgs.brightnessctl}/bin/brightnessctl -r"
            else if hyprland then
              "${pkgs.hyprland}/bin/hyprctl dispatch dpms on && ${pkgs.brightnessctl}/bin/brightnessctl -r"
            else
              "";
        };
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
        ++ optionals (mango && cfg.lockScreen) [
          {
            timeout = 600;
            command = "${pkgs.wlr-dpms}/bin/wlr-dpms off";
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
            resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors && ${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
        ]
        ++ optionals (mango && !cfg.lockScreen) [
          {
            timeout = 300;
            command = "${pkgs.wlr-dpms}/bin/wlr-dpms off";
            resumeCommand = "${pkgs.wlr-dpms}/bin/wlr-dpms on && ${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
        ]
        ++ optionals (hyprland && !cfg.lockScreen) [
          {
            timeout = 300;
            command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
            resumeCommand = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on && ${pkgs.brightnessctl}/bin/brightnessctl -r";
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
