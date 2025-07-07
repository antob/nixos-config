{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.polybar;

  colors = config.antob.color-scheme.colors;
  colMB = "282c34";

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
    antob.system.fonts.fonts = [ pkgs.sfns-display-font ];

    antob.home.extraOptions = {
      services.polybar = {
        enable = true;

        extraConfig = ''
          [bar/menu]
          width = 100%
          height = 42
          radius = 0
          line-size = 3
          padding-left = 3
          offset-y = 0
          offset-x = 0

          font-0 = "SFNS Display:style=Bold:size=11;3"
          font-1 = "Hack Nerd Font:size=16;3"
          font-2 = "SFNS Display:style=Bold:size=13;3"

          foreground = #${colors.base07}
          background = #${colMB}

          enable-ipc = true

          monitor = ''${env:MONITOR:}

          wm-restack = generic

          modules-left = xmonad title
          ; modules-right = cpu spacer memory spacer disk_usage spacer external_ip spacer wireless-network check_vpn spacer battery spacer check_kbd_variant spacer date spacer
          modules-right = cpu spacer memory spacer filesystem spacer external_ip spacer wireless-network check_vpn spacer battery spacer check_kbd_variant spacer date spacer

          tray-position = ''${env:TRAY_POSITION:right}
          tray-padding = 0
          tray-maxsize = 20
          tray-offset-x = 0
          tray-offset-y = 0
          tray-foreground = #${colors.base07}

          [layout]
          module-padding = 0

          [global/wm]
          margin-bottom = 0

          [settings]
          screenchange-reload = true

          ; Compositing operators
          compositing-background = source
          compositing-foreground = over
          compositing-overline = over
          compositing-underline = over
          compositing-border = over

          ; Define fallback values used by all module formats
          format-foreground =
          format-background =
          format-underline =
          format-overline =
          format-spacing = 0
          format-padding = 0
          format-margin = 0
          format-offset = 0

          ; Enables pseudo-transparency for the bar
          ; If set to true the bar can be transparent without a compositor.
          pseudo-transparency = false

          [module/separator]
          type = custom/text
          content = %{T2}|%{T-}
          content-foreground = #666666

          [module/spacer]
          type = custom/text
          content = %{T2} %{T-}
          content-foreground = #000000

          [module/battery]
          type = internal/battery
          battery = BAT0
          adapter = AC
          poll-interval = 5
          time-format = %H:%M

          format-foreground = #${colors.base0A}
          format-charging = <label-charging>
          format-charging-background = #${colMB}
          format-charging-foreground = #${colors.base0A}
          format-charging-padding = ''${layout.module-padding}
          format-discharging = <ramp-capacity>  <label-discharging>
          format-discharging-background = #${colMB}
          format-discharging-foreground = #${colors.base0A}
          format-discharging-padding = ''${layout.module-padding}
          format-full = <ramp-capacity> <label-full>

          label-charging =     %percentage%%
          label-discharging = %percentage%%  %consumption%W
          label-full = "  %percentage%%"
          label-full-background = #${colMB}
          label-full-foreground = #${colors.base0A}
          label-full-padding = ''${layout.module-padding}

          ramp-capacity-0 = "    "
          ramp-capacity-0-foreground = #${colors.base09}
          ramp-capacity-1 = "    "
          ramp-capacity-1-foreground = #${colors.base09}
          ramp-capacity-2 = "    "
          ramp-capacity-2-foreground = #${colors.base0B}
          ramp-capacity-3 = "    "
          ramp-capacity-3-foreground = #${colors.base0B}
          ramp-capacity-4 = "    "
          ramp-capacity-4-foreground = #${colors.base11}
          ramp-capacity-5 = "    "
          ramp-capacity-5-foreground = #${colors.base0A}
          ramp-capacity-6 = "    "
          ramp-capacity-6-foreground = #${colors.base0A}
          ramp-capacity-7 = "    "
          ramp-capacity-7-foreground = #${colors.base0A}
          ramp-capacity-8 = "    "
          ramp-capacity-8-foreground = #${colors.base0A}
          ramp-capacity-9 = "    "
          ramp-capacity-9-foreground = #${colors.base0A}

          [module/cpu]
          type = internal/cpu
          interval = 1
          format = <label>
          format-prefix = "    "
          format-background = #${colMB}
          format-foreground = #${colors.base0B}
          format-padding = ''${layout.module-padding}
          label = " CPU %percentage:2%%"

          [module/date]
          type = internal/date
          interval = 1.0
          time =    %a %e %b      %H:%M
          time-alt =    %a %e %b %Y w%W      %H:%M
          format = <label>
          format-foreground = #${colors.base07}
          format-padding = ''${layout.module-padding}
          label = %time%

          [module/filesystem]
          type = internal/fs
          mount-0 = /
          interval = 30
          fixed-values = true
          format-mounted = <label-mounted>
          format-mounted-prefix = "  "
          format-mounted-background = #${colMB}
          format-mounted-foreground = #${colors.base0C}
          format-mounted-padding = ''${layout.module-padding}
          label-mounted = "  %free%"

          [module/memory]
          type = internal/memory
          interval = 3

          format = <label>
          format-prefix = "   "
          format-background = #${colMB}
          format-foreground = #${colors.base0E}
          format-padding = ''${layout.module-padding}
          label = " RAM %percentage_used:2%%"

          [module/wireless-network]
          type = internal/network
          interface = wlan0
          format-connected = <label-connected>
          format-connected-prefix = "     "
          format-connected-foreground = #${colors.base0A}
          format-disconnected = <label-disconnected>
          format-disconnected-prefix = "睊   "
          format-disconnected-foreground = #${colors.base09}
          label-connected = %essid% %signal%% %local_ip%
          label-disconnected = No connection

          [module/title]
          type = internal/xwindow
          format = <label>
          format-background = #${colMB}
          format-foreground = #${colors.base07}
          format-padding = ''${layout.module-padding}
          label = %{T3}%title%%{T-}
          label-maxlen = 45
          label-empty = Desktop

          [module/check_fw]
          type = custom/script
          exec = ~/.config/polybar/scripts/check-fw
          interval = 5
          label-background = #${colors.base0D}
          label-foreground = #${colMB}
          format = <label>
          format-padding = 2

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
          label-background = #${colMB}
          label-foreground = #${colors.base0B}
          format = <label>
          format-padding = 1

          [module/check_vpn]
          type = custom/script
          exec = ${check-vpn}/bin/check-vpn
          interval = 5
          label-background = #${colors.base0A}
          label-foreground = #${colMB}
          format = <label>
          format-padding = 2

          [module/external_ip]
          type = custom/script
          exec = ${external-ip}/bin/external-ip
          interval = 10
          format-background = #${colMB}
          format-foreground = #${colors.base11}
          format =     <label>

          [module/disk_usage]
          type = custom/script
          exec = ${disk-usage}/bin/disk-usage
          interval = 10
          format-background = #${colMB}
          format-foreground = #${colors.base0C}
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
