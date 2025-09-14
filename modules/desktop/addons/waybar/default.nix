{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.waybar;
  colors = config.antob.color-scheme.colors;
  external-ip = lib.getExe (pkgs.callPackage ./scripts/external-ip.nix { });
  mic-cam-usage = lib.getExe (pkgs.callPackage ./scripts/mic-cam-usage.nix { });
in
{
  options.antob.desktop.addons.waybar = with types; {
    enable = mkEnableOption "Whether or not to install and configure Waybar.";
    enableSystemd = mkBoolOpt true "Whether to enable Waybar systemd integration.";
  };

  config = mkIf cfg.enable {
    antob.system.fonts.fonts = [ pkgs.sfns-display-font ];

    antob.home.extraOptions = {
      programs.waybar = {
        enable = true;
        systemd.enable = cfg.enableSystemd;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            spacing = 0;
            height = 26;

            modules-left = [
              "hyprland/workspaces"
            ];

            modules-right = [
              "group/tray-expander"
              "bluetooth"
              "custom/external-ip"
              "network"
              "pulseaudio"
              "memory"
              "cpu"
              "battery"
              "custom/vpn"
              "custom/idle"
              "custom/webcam"
              "clock"
            ];

            "hyprland/workspaces" = {
              on-click = "activate";
              format = "{icon}";
              format-icons = {
                default = "";
                "1" = "1";
                "2" = "2";
                "3" = "3";
                "4" = "4";
                "5" = "5";
                "6" = "6";
                "7" = "7";
                "8" = "8";
                "9" = "9";
                active = "󱓻";
              };
              persistent-workspaces = {
                "1" = [ ];
                "2" = [ ];
                "3" = [ ];
                "4" = [ ];
                "5" = [ ];
                "6" = [ ];
                "7" = [ ];
                "8" = [ ];
              };
            };

            cpu = {
              interval = 5;
              format = " {usage:2}%";
              on-click = "alacritty --class=TUI.float.lg -e ${pkgs.btop}/bin/btop";
            };

            memory = {
              interval = 5;
              format = "  {percentage}%";
              on-click = "alacritty --class=TUI.float.lg -e ${pkgs.btop}/bin/btop";
            };

            clock = {
              format = "   {:%a %d %b %H:%M}";
              format-alt = "   {:%a %d %b %H:%M v%W}";
              tooltip = false;
            };

            network = {
              format-icons = [
                "󰤯"
                "󰤟"
                "󰤢"
                "󰤥"
                "󰤨"
              ];
              format = "{icon}";
              format-wifi = "{icon}";
              format-ethernet = "󰀂";
              format-disconnected = "󰖪";
              tooltip-format-wifi = "{essid} {signalStrength}% ({frequency} GHz)\n{ipaddr}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
              tooltip-format-ethernet = "{ipaddr}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
              tooltip-format-disconnected = "Disconnected";
              interval = 5;
              spacing = 1;
              on-click = "alacritty --class=TUI.float -e impala";
            };

            battery = {
              format = "{icon}  {capacity}%";
              #format-discharging = "{icon}";
              #format-charging = "{icon}";
              format-plugged = " {capacity}%";
              format-icons = {
                charging = [
                  "󰢜"
                  "󰂆"
                  "󰂇"
                  "󰂈"
                  "󰢝"
                  "󰂉"
                  "󰢞"
                  "󰂊"
                  "󰂋"
                  "󰂅"
                ];
                default = [
                  "󰁺"
                  "󰁻"
                  "󰁼"
                  "󰁽"
                  "󰁾"
                  "󰁿"
                  "󰂀"
                  "󰂁"
                  "󰂂"
                  "󰁹"
                ];
              };
              format-full = "󰂅";
              tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
              tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
              interval = 5;
              # on-click = "omarchy-menu power";
              states = {
                warning = 20;
                critical = 10;
              };
            };

            bluetooth = {
              format = "";
              format-disabled = "󰂲";
              format-connected = "";
              tooltip-format = "Devices connected: {num_connections}";
              on-click = "alacritty --class=TUI.float -e bluetui";
            };

            pulseaudio = {
              format = "{icon}";
              on-click = "alacritty --class=Wiremix -e wiremix";
              on-click-right = "${pkgs.pamixer}/bin/pamixer -t";
              tooltip-format = "Playing at {volume}%";
              scroll-step = 5;
              format-muted = "󰝟";
              format-icons = {
                default = [
                  ""
                  ""
                  ""
                ];
              };
            };

            "group/tray-expander" = {
              orientation = "inherit";
              drawer = {
                transition-duration = 600;
                children-class = "tray-group-item";
              };
              modules = [
                "custom/expand-icon"
                "tray"
              ];
            };

            "custom/expand-icon" = {
              format = " ";
              tooltip = false;
            };

            "custom/vpn" = {
              format = "  ";
              exec = "echo '{\"class\": \"connected\", \"tooltip\": \"VPN connection active\"}'";
              exec-if = "test -d /proc/sys/net/ipv4/conf/tun0 -o -d /proc/sys/net/ipv4/conf/ppp0";
              return-type = "json";
              interval = 5;
            };

            "custom/idle" = {
              format = "   ";
              exec = "echo '{\"tooltip\": \"Not locking computer when idle\"}'";
              exec-if = "test `systemctl --user is-active hypridle.service` = inactive";
              return-type = "json";
              interval = 5;
            };

            "custom/external-ip" = {
              interval = 10;
              exec = "${external-ip}";
              format = "{}";
              return-type = "json";
              on-click = "ip=`curl -s --connect-timeout 1 http://ifconfig.me`; wl-copy $ip; notify-send \"󰆏  External IP copied ($ip)\"";
            };

            "custom/webcam" = {
              exec = "${mic-cam-usage}";
              interval = 5;
              format = "{0}{1}";
              escape = true;
            };

            tray = {
              icon-size = 12;
              spacing = 12;
            };
          };
        };

        style = ''
          * {
            background-color: #${colors.base10};
            color: #${colors.base07};

            border: none;
            border-radius: 0;
            min-height: 0;
            font-family: SFNS Display;
            font-size: 14px;
            font-weight: 500;
          }

          .modules-left {
            margin-left: 8px;
          }

          .modules-right {
            margin-right: 8px;
          }

          #workspaces button {
            all: initial;
            padding: 0 6px;
            margin: 0 1.5px;
            min-width: 9px;
          }

          #workspaces button.empty {
            opacity: 0.5;
          }

          #tray,
          #memory,
          #cpu,
          #battery,
          #network,
          #bluetooth,
          #clock,
          #pulseaudio {
            min-width: 12px;
            margin: 0 7.5px;
          }

          #clock {
            font-weight: 600;
          }

          #custom-expand-icon {
            margin-right: 7px;
          }

          #custom-vpn,
          #custom-idle,
          #custom-webcam {
            color: #${colors.base09};
          }

          #custom-external-ip.disconnected {
            color: #${colors.base09};
          }

          tooltip {
            padding: 2px;
          }

          .hidden {
            opacity: 0;
          }
        '';
      };
    };
  };
}
