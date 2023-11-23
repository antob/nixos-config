{ config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.hyprland;
  gtkCfg = config.antob.desktop.addons.gtk;
  colors = config.antob.color-scheme.colors;

  wcwd = pkgs.callPackage ./scripts/wcwd.nix { };
  dm-logout = pkgs.callPackage ./scripts/dm-logout.nix { };
  dm-vpn = pkgs.callPackage ./scripts/dm-vpn.nix { };
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

    antob = {
      desktop.addons = {
        gtk = enabled;
        waybar = enabled;
        keyring = enabled;
        udisks2 = enabled;
        yubikey-touch-detector = enabled;
      };

      tools.tofi = enabled;

      home.extraOptions = {
        xsession.enable = true;

        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = gtkCfg.theme.name;
            cursor-theme = gtkCfg.cursor.name;
            cursor-size = gtkCfg.cursor.size;
          };
        };

        wayland.windowManager.hyprland = {
          enable = true;
          systemd.enable = true;
          xwayland.enable = true;

          extraConfig = ''
            monitor=eDP-1,highres,auto,1.5
            monitor=,preferred,auto,auto
            
            exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
            exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
            exec-once = ${pkgs.hyprpaper}/bin/hyprpaper
            exec-once = ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
            exec-once = ${pkgs.blueman}/bin/blueman-applet
            exec-once = hyprctl setcursor ${gtkCfg.cursor.name} ${toString gtkCfg.cursor.size}

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
                col.active_border = rgba(${colors.base0E}ff)
                col.inactive_border = rgba(${colors.base12}aa)

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
                enabled = no
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
            # Workspaces
            windowrulev2 = workspace 2,class:^(firefox|librewolf)$
            windowrulev2 = workspace 3,class:^codium.*

            # Floating windows
            windowrulev2 = float,title:Open File
            windowrulev2 = move center,title:Open File
            windowrulev2 = size 900 500,title:Open File
            windowrulev2 = noborder,title:Open File

            # Opacity
            windowrulev2 = opacity 0.8 override 0.8 override, class:^(kitty)$

            ## Key bindings
            $mainMod = SUPER
            bind = $mainMod, Q, killactive, 
            bind = $mainMod, C, exit, 
            bind = $mainMod, V, togglefloating, 
            bind = $mainMod, P, pseudo, # dwindle
            bind = $mainMod, J, togglesplit, # dwindle
            bind = $mainMod, F, fullscreen, 1
            bind = $mainMod, X, exec, ${dm-logout}/bin/dm-logout
            bind = $mainMod, P, exec, ${dm-vpn}/bin/dm-vpn

            # Apps
            bind = $mainMod, RETURN, exec, kitty --working-directory `${wcwd}/bin/wcwd`
            bind = $mainMod, W, exec, librewolf
            bind = $mainMod, D, exec, ${pkgs.tofi}/bin/tofi-drun

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

        xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
      };

      system.env = {
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
        XDG_SESSION_TYPE = "wayland";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        GTK_USE_PORTAL = "1";
        NIXOS_XDG_OPEN_USE_PORTAL = "1";
      };
    };

    # Desktop portal
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    environment.systemPackages = with pkgs; [
      hyprpaper
      wl-clipboard
      hyprland-protocols
      xorg.xlsclients
      brightnessctl
      # dunst
      # libnotify
      # rofi-wayland
      # hyprpicker
      # swayidle
      # swaylock
    ];

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
