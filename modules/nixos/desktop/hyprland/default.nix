{ config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.hyprland;
  gtkCfg = config.antob.desktop.addons.gtk;

  wcwd = pkgs.callPackage ./scripts/wcwd.nix { };
  bm-logout = pkgs.callPackage ./scripts/bm-logout.nix { };
  bm-vpn = pkgs.callPackage ./scripts/bm-vpn.nix { };
in
{
  options.antob.desktop.hyprland = with types; {
    enable = mkEnableOption "Enable Hyprland.";
  };

  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
        enableNvidiaPatches = false;
      };

      dconf.enable = true;
    };

    antob.home.extraOptions = {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        xwayland.enable = true;

        extraConfig = ''
          monitor=,preferred,auto,auto
          
          exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
          exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
          exec-once = ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
          exec-once = ${pkgs.blueman}/bin/blueman-applet

          input {
              kb_layout = se
              kb_variant = us
              kb_model =
              kb_options = caps:ctrl_modifier
              kb_rules =

              repeat_rate = 30
              repeat_delay = 200

              follow_mouse = 1

              touchpad {
                  natural_scroll = yes
              }

              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
          }

          general {
              gaps_in = 5
              gaps_out = 8
              border_size = 2
              col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
              col.inactive_border = rgba(595959aa)

              layout = master

              # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
              allow_tearing = false
          }

          decoration {
              rounding = 5
              
              blur {
                  enabled = true
                  size = 5
                  passes = 2
              }

              drop_shadow = no
          }

          animations {
              enabled = yes

              bezier = overshot, 0.05, 0.9, 0.1, 1.05
              bezier = smoothOut, 0.5, 0, 0.99, 0.99
              bezier = smoothIn, 0.5, -0.5, 0.68, 1.5
              bezier = rotate,0,0,1,1

              animation = windows, 1, 5, overshot, slide
              animation = windowsIn, 1, 3, smoothOut
              animation = windowsOut, 1, 3, smoothOut
              animation = windowsMove, 1, 4, smoothIn, slide
              animation = border, 1, 6, default
              animation = fade, 1, 5, smoothIn
              animation = fadeDim, 1, 5, smoothIn
              animation = workspaces, 1, 6, default
              animation = borderangle, 1, 20, rotate, loop    # borderangle - for animating the border's gradient angle
          }

          dwindle {
              pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
              preserve_split = yes # you probably want this
          }

          master {
              new_is_master = true
              new_on_top = true
              mfact = 0.50
              no_gaps_when_only = 1
          }

          gestures {
              # See https://wiki.hyprland.org/Configuring/Variables/ for more
              workspace_swipe = off
          }

          misc {
            disable_hyprland_logo = true
          }

          ## Window rules
          windowrulev2 = workspace 2,class:^(firefox|librewolf)$
          windowrulev2 = workspace 3,class:^codium.*

          # Opacity
          windowrulev2 = opacity 0.8 override 0.8 override, class:^(kitty)$

          $mainMod = SUPER

          bind = $mainMod, Q, killactive, 
          bind = $mainMod, C, exit, 
          bind = $mainMod, V, togglefloating, 
          bind = $mainMod, P, pseudo, # dwindle
          bind = $mainMod, J, togglesplit, # dwindle
          bind = $mainMod, F, fullscreen, 1
          bind = $mainMod, X, exec, ${bm-logout}/bin/bm-logout
          bind = $mainMod, P, exec, ${bm-vpn}/bin/bm-vpn

          # Apps
          bind = $mainMod, RETURN, exec, kitty --working-directory `${wcwd}/bin/wcwd`
          bind = $mainMod, W, exec, librewolf
          bind = $mainMod, D, exec, bemenu-run

          # Move focus with mainMod + left and right arrow
          bind = $mainMod, right, layoutmsg, cyclenext
          bind = $mainMod, left, layoutmsg, cycleprev

          # Swap windows
          bind = $mainMod SHIFT, right, layoutmsg, swapnext
          bind = $mainMod SHIFT, left, layoutmsg, swapprev

          # Cycle workspaces
          bind = $mainMod, Tab, workspace, e+1
          bind = $mainMod SHIFT, Tab, workspace, e-1

          # Swap current window with master
          bind = $mainMod, BackSpace, layoutmsg, swapwithmaster auto

          # Media keys
          bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
          bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%

          # Switch workspaces with mainMod + [1-9]
          bind = $mainMod, 1, workspace, 1
          bind = $mainMod, 2, workspace, 2
          bind = $mainMod, 3, workspace, 3
          bind = $mainMod, 4, workspace, 4
          bind = $mainMod, 5, workspace, 5
          bind = $mainMod, 6, workspace, 6
          bind = $mainMod, 7, workspace, 7
          bind = $mainMod, 8, workspace, 8
          bind = $mainMod, 9, workspace, 9

          # Move active window to a workspace with mainMod + SHIFT + [1-9]
          bind = $mainMod SHIFT, 1, movetoworkspace, 1
          bind = $mainMod SHIFT, 2, movetoworkspace, 2
          bind = $mainMod SHIFT, 3, movetoworkspace, 3
          bind = $mainMod SHIFT, 4, movetoworkspace, 4
          bind = $mainMod SHIFT, 5, movetoworkspace, 5
          bind = $mainMod SHIFT, 6, movetoworkspace, 6
          bind = $mainMod SHIFT, 7, movetoworkspace, 7
          bind = $mainMod SHIFT, 8, movetoworkspace, 8
          bind = $mainMod SHIFT, 9, movetoworkspace, 9

          # Move/resize windows with mainMod + LMB/RMB and dragging
          bindm = $mainMod, mouse:272, movewindow
          bindm = $mainMod, mouse:273, resizewindow
        '';
      };

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
            ];

            modules-center = [
              "hyprland/window"
            ];

            modules-right = [
              "memory"
              "battery"
              "clock"
              "tray"
            ];

            "hyprland/workspaces" = {
              format = "{icon}";
              format-icons = {
                default = "";
                active = "";
                urgent = "";
              };
            };
          };
        };

        style = ''
          /* -----------------------------------------------------
           * General 
           * ----------------------------------------------------- */
          * {
            font-size: 12px;
            font-family: Hack Nerd Font;
          }

          window#waybar {
            background-color: rgba(40, 42, 54, 0.8);
            border-bottom: 1px solid rgba(40, 42, 55, 0.1);
            border-radius: 0px;
            color: #f8f8f2;
          }

          /* -----------------------------------------------------
           * Workspaces 
           * ----------------------------------------------------- */
          #workspaces {
            background-color: inherit;
          }

          #workspaces button:hover {
            background: inherit;
          }

          /* -----------------------------------------------------
           * Tooltips
           * ----------------------------------------------------- */
          tooltip {
            background: #282a36;
            border: 1px solid #bd93f9;
            border-radius: 10px;
          }

          tooltip label {
            color: #f8f8f2;
          }

          /* -----------------------------------------------------
           * Window
           * ----------------------------------------------------- */
          #window {
            color: #f8f8f2;
            padding: 4px 10px;
          }

          #custom-packages {
            color: #ff79c6;
            padding: 4px 10px;
          }

          #memory {
            color: #ffb86c;
            padding: 4px 10px;
          }

          #clock {
            color: #50fa7b;
            padding: 4px 10px;
          }

          #cpu {
            color: #8be9fd;
            padding: 4px 10px;
          }

          #disk {
            color: #50fa7b;
            padding: 4px 10px;
          }

          #battery {
            color: #f8f8f2;
            padding: 4px 10px;
          }

          #network {
            color: #f8f8f2;
            padding: 4px 10px;
          }

          #tray {
            padding: 2px 10px;
          }

        '';
      };
    };

    antob.system.env = {
      BEMENU_OPTS = "-i -H 30 --ch 16 --cw 2 --hp 6 -p '' --fn 'SFNS Display Bold 9' --hb '#56b6c2' --hf '#191919' --nf '#ebdbb2' --nb '#282c34' --ab '#282c34' --af '#ebdbb2' --fb '#282c34' --ff '#ebdbb2' --tb '#56b6c2' --tf '#191919'";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      # POLKIT_AUTH_AGENT = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
      XDG_SESSION_TYPE = "wayland";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      GTK_USE_PORTAL = "1";
      NIXOS_XDG_OPEN_USE_PORTAL = "1";
    };

    # Desktop portal
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    environment.systemPackages = with pkgs; [
      # dunst
      # libnotify
      # rofi-wayland
      # dmenu-wayland
      bemenu
      swww
      wl-clipboard
      hyprland-protocols
      # hyprpicker
      # swayidle
      # swaylock
      xorg.xlsclients
      brightnessctl
      xcwd
      dmidecode
    ];

    # Desktop additions
    antob.desktop.addons = {
      gtk = enabled;
      keyring = enabled;
      udisks2 = enabled;
      yubikey-touch-detector = enabled;
    };

    antob.home.extraOptions = {
      xsession.enable = true;

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = gtkCfg.theme.name;
          cursor-theme = gtkCfg.cursor.name;
          cursor-size = gtkCfg.cursor.size;
        };
      };
    };

    services.gnome.at-spi2-core.enable = true;

    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Enable LightDm display manager.
      displayManager = {
        lightdm.enable = true;
        defaultSession = "hyprland";
        autoLogin = mkIf config.antob.user.autoLogin {
          enable = true;
          user = config.antob.user.name;
        };
      };
    };
  };
}
