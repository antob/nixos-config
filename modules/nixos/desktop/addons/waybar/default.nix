{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.addons.waybar;
  colors = config.antob.color-scheme.colors;
  external-ip = pkgs.callPackage ./scripts/external-ip.nix { };
in
{
  options.antob.desktop.addons.waybar = with types; {
    enable = mkEnableOption "Whether or not to install and configure waybar.";
  };

  config = mkIf cfg.enable {
    antob.system.fonts.fonts = with pkgs; [ antob.sfns-display-font ];

    antob.home.extraOptions = {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        package = pkgs.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 32;

            modules-left = [
              "hyprland/workspaces"
              "hyprland/window"
            ];

            modules-right = [
              "cpu"
              "memory"
              "disk"
              "custom/external-ip"
              "network#wlan0"
              "custom/vpn"
              "battery"
              "clock"
              "tray"
            ];

            "hyprland/workspaces" = {
              sort-by = "number";
              format = "{icon}";
              format-icons = {
                default = "<span size='175%'></span>";
                active = "<span size='175%'></span>";
                urgent = "<span size='175%'></span>";
              };
              persistent-workspaces = {
                "*" = 5;
              };
            };

            "hyprland/window" = {
              max-length = 70;
              separate-outputs = false;
            };

            cpu = {
              interval = 5;
              format = "   CPU {usage}%";
              on-click = "${pkgs.kitty}/bin/kitty --start-as=fullscreen --title btm bash -ci 'btm'";
            };

            memory = {
              interval = 5;
              format = "   RAM {}%";
              on-click = "${pkgs.kitty}/bin/kitty --start-as=fullscreen --title btm bash -ci 'btm'";
            };

            disk = {
              format = "  {free}";
              path = "/";
              on-click = "${pkgs.kitty}/bin/kitty --start-as=fullscreen --title btm bash -ci 'btm'";
            };

            "custom/external-ip" = {
              interval = 10;
              exec = "${external-ip}/bin/external-ip";
              format = "{}";
              return-type = "json";
            };

            "network#wlan0" = {
              interface = "wlan0";
              interval = 5;
              format-icons = [
                "󰤯"
                "󰤟"
                "󰤢"
                "󰤥"
                "󰤨"
              ];
              tooltip-format = "Connected to {essid} {signalStrength}% ({ipaddr})";
              tooltip-format-disconnected = "Not connected.";
              format-wifi = "{icon}   {essid}";
              format-disconnected = "󰤮";
            };

            "custom/vpn" = {
              format = "  ";
              exec = "echo '{\"class\": \"connected\", \"tooltip\": \"VPN connection active\"}'";
              exec-if = "test -d /proc/sys/net/ipv4/conf/tun0 -o -d /proc/sys/net/ipv4/conf/ppp0";
              return-type = "json";
              interval = 5;
            };

            battery = {
              interval = 5;
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{icon}    {capacity}%";
              format-discharging = "{icon}    {capacity}% {power:.1f}W";
              format-charging = "󰂄 {capacity}%";
              format-plugged = "󱘖 {capacity}%";
              format-icons = [
                " "
                " "
                " "
                " "
                " "
                " "
                " "
                " "
                " "
                " "
              ];
              on-click = "";
            };

            clock = {
              format = "{:  %H:%M}";
              tooltip = true;
              tooltip-format = "{:  %H:%M      %A %e %B v.%W}";
            };

            tray = {
              icon-size = 20;
              spacing = 8;
            };
          };
        };

        style = ''
          /* -----------------------------------------------------
          * General 
          * ----------------------------------------------------- */
          * {
            font-size: 14px;
            font-weight: 600;
            font-family: SFNS Display;
          }

          window#waybar {
            background-color: #${colors.base10};
            color: #${colors.base07};
            opacity: 0.9;
            border-radius: 0px;
          }

          /* -----------------------------------------------------
          * Workspaces 
          * ----------------------------------------------------- */
          #workspaces {
            background-color: inherit;
            margin-top: -50px;
            margin-bottom: -50px
          }

          #workspaces button:hover {
            background: inherit;
          }

          #workspaces button {
            color: #${colors.base0E};
          }

          #workspaces button.empty {
            color: #${colors.base12};
          }

          #workspaces button.visible {
            color: #${colors.base0A};
          }

          #workspaces button.active {
            color: #${colors.base0A};
          }

          #workspaces button.urgent {
            color: #${colors.base0B};
          }

          /* -----------------------------------------------------
          * Tooltips
          * ----------------------------------------------------- */
          tooltip {
            background: #${colors.base10};
            border: 2px solid #${colors.base0E};
            color: #${colors.base07};
            border-radius: 10px;
          }

          tooltip label {
            color: #${colors.base07};
          }

          /* -----------------------------------------------------
          * Window
          * ----------------------------------------------------- */
          #window {
            color: #${colors.base07};
            padding: 4px 10px;
            font-weight: normal;
          }

          #cpu {
            color: #${colors.base0B};
            padding: 4px 10px;
          }

          #memory {
            color: #${colors.base0E};
            padding: 4px 10px;
          }

          #disk {
            color: #${colors.base0C};
            padding: 4px 10px;
          }

          #custom-external-ip {
            color: #${colors.base0A};
            padding: 4px 0px 4px 10px;
          }
          #custom-external-ip.disconnected {
            color: #${colors.base09};
          }

          #network {
            color: #${colors.base0A};
            padding: 4px 10px 4px 0px;
          }
          #network.disabled,
          #network.disconnected {
            color: #${colors.base09};
          }

          #custom-vpn {
            color: #${colors.base0F};
            background-color: #${colors.base0A};
          }

          #battery {
            color: #${colors.base0A};
            padding: 4px 10px;
          }
          #battery.warning {
            color: #${colors.base0B};
          }
          #battery.critical {
            color: #${colors.base09};
          }

          #clock {
            color: #${colors.base07};
            padding: 4px 10px;
          }

          #tray {
            color: #${colors.base07};
            padding: 2px 10px;
          }
        '';
      };
    };
  };
}