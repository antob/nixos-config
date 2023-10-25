{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.addons.polybar;

  colors = builtins.readFile ./colors.ini;
  modules = builtins.readFile ./modules.ini;

  check-kbd-variant = pkgs.callPackage ./scripts/check-kbd-variant.nix { };
  check-vpn = pkgs.callPackage ./scripts/check-vpn.nix { };
  external-ip = pkgs.callPackage ./scripts/external-ip.nix { };
  disk-usage = pkgs.callPackage ./scripts/disk-usage.nix { };

in
{
  options.antob.desktop.addons.polybar = with types; {
    enable = mkEnableOption "Whether or not to install and configure polybar.";
    trayOutput = mkOpt types.str "eDP-1" "The name of the monitor to display the tray.";
  };

  config = mkIf cfg.enable {
    antob.system.fonts.fonts = with pkgs; [ antob.sfns-display-font ];

    antob.home.extraOptions = {
      services.polybar = {
        enable = true;

        config = ./config.ini;
        extraConfig = colors + modules + ''
          [module/xmonad]
          type = custom/script
          exec = ${pkgs.xmonad-log}/bin/xmonad-log
          tail = true
          interval = 1
          format = %{T3}<label>%{T-}

          [module/check_kbd_variant]
          type = custom/script
          exec = ${check-kbd-variant}/bin/check-kbd-variant
          interval = 2
          label-background = ''${colors.mb}
          label-foreground = ''${colors.base09}
          format = <label>
          format-padding = 1

          [module/check_vpn]
          type = custom/script
          exec = ${check-vpn}/bin/check-vpn
          interval = 5
          label-background = ''${colors.base0B}
          label-foreground = ''${colors.mb}
          format = <label>
          format-padding = 2

          [module/external_ip]
          type = custom/script
          exec = ${external-ip}/bin/external-ip
          interval = 10
          format-background = ''${colors.mb}
          format-foreground = ''${colors.base0A}
          format =     <label>

          [module/disk_usage]
          type = custom/script
          exec = ${disk-usage}/bin/disk-usage
          interval = 10
          format-background = ''${colors.mb}
          format-foreground = ''${colors.base0D}
          format =     <label>
        '';

        script = ''
          tray_output=${cfg.trayOutput}

          for m in $(polybar --list-monitors | ${pkgs.coreutils}/bin/cut -d":" -f1); do
              tray_pos=none
              if [[ $m == $tray_output ]]; then
                tray_pos=right
              fi

              MONITOR=$m TRAY_POSITION=$tray_pos polybar menu &
          done
        '';
      };
    };
  };
}
