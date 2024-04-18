{ config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.hyprland;
  gtkCfg = config.antob.desktop.addons.gtk;
  colors = config.antob.color-scheme.colors;

  wcwd = pkgs.callPackage ./scripts/wcwd.nix { };
  sleep = pkgs.callPackage ./scripts/sleep.nix { };
  toggle-laptop-display = pkgs.callPackage ./scripts/toggle-laptop-display.nix { };
  dm-logout = pkgs.callPackage ./scripts/dm-logout.nix { };
  dm-vpn = pkgs.callPackage ./scripts/dm-vpn.nix { };
  dm-firefox-profile = pkgs.callPackage ./scripts/dm-firefox-profile.nix { };
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
      };

      dconf.enable = true;
    };

    antob = {
      desktop.addons = {
        gtk = enabled;
        waybar = enabled;
        keyring = enabled;
        udisks2 = enabled;
        mako = enabled;
        swayosd = enabled;
        swaylock = enabled;
      };

      tools.tofi = enabled;
      services.gammastep = enabled;

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

        home.file.".config/swappy/config".text = ''
          [Default]
          save_dir=$HOME/Pictures/Screenshots
          save_filename_format=Screenshot-%Y%m%d-%H%M%S.png
          paint_mode=rectangle
          early_exit=true
          line_size=2
          text_size=12
          paint_mode=rectangle
        '';

        wayland.windowManager.hyprland = {
          enable = true;
          systemd.enable = true;
          xwayland.enable = true;

          extraConfig = ''
            # Internal screen
            monitor=eDP-1,highres@60,1767x1440,1.5

            # Home office extra screen
            monitor=desc:Acer Technologies XB273U TJ5EE0018521,2560x1440@144,1512x288,1.25

            # OBIT ultra widemonitor
            monitor=desc:LG Electronics LG HDR DQHD 0x000320C3,5120x1440@60.0,0x0,1.0
            monitor=desc:Samsung Electric Company LS49A950U HNTW900886,5120x1440@120,0x0,1.0

            # Set by nwg-displays
            source = ~/.config/hypr/monitors.conf

            # Default
            monitor=,preferred,auto,auto

            source = ~/.config/hypr/workspaces.conf

            exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
            exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
            exec-once = ${pkgs.hyprpaper}/bin/hyprpaper
            exec-once = ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
            exec-once = ${pkgs.blueman}/bin/blueman-applet
            exec-once = ${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify
            exec-once = hyprctl setcursor ${gtkCfg.cursor.name} ${toString gtkCfg.cursor.size}
            exec-once = ${sleep}/bin/sleep
            exec-once = ${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit

            # Make default apps work with xdg-open
            exec-once = systemctl --user import-environment PATH && systemctl --user restart xdg-desktop-portal.service

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

            device {
              name = modern-mobile-mouse
              sensitivity = -0.5
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
                always_center_master = true
            }

            group {
              focus_removed_window = true

              col.border_active = rgba(${colors.base0A}ff)
              col.border_inactive = rgba(${colors.base08}aa)

              groupbar {
                enabled = false
              }
            }
            
            gestures {
                # See https://wiki.hyprland.org/Configuring/Variables/ for more
                workspace_swipe = off
            }

            misc {
              disable_hyprland_logo = true
              key_press_enables_dpms = true
            }

            debug {
              disable_scale_checks = 1
            }

            # ### Window rules
            # Workspaces
            windowrulev2 = workspace 2,class:^(firefox|librewolf)$
            windowrulev2 = workspace 3,class:^codium.*
            windowrulev2 = workspace 3,class:^code-url-handler$
            windowrulev2 = workspace 3,class:^code-insiders-url-handler$
            windowrulev2 = workspace 5,class:^Slack$

            # Floating windows
            windowrulev2 = float,class:^xdg-desktop-portal-gtk$
            windowrulev2 = size 900 500,class:^xdg-desktop-portal-gtk$
            windowrulev2 = move center,class:^xdg-desktop-portal-gtk$
            windowrulev2 = noborder,class:^xdg-desktop-portal-gtk$

            windowrulev2 = float,title:Bluetooth Devices
            windowrulev2 = size 900 500,title:Bluetooth Devices
            windowrulev2 = move center,title:Bluetooth Devices

            windowrulev2 = float,class:nm-connection-editor
            windowrulev2 = float,class:pavucontrol
            
            windowrulev2 = float,class:(nwg-displays)
            windowrulev2 = size 965 715,class:(nwg-displays)
            windowrulev2 = move center,class:(nwg-displays)

            # Opacity
            windowrulev2 = opacity 0.8 override 0.8 override, class:^(kitty)$
            windowrulev2 = opacity 0.8 override 0.8 override, class:^(alacritty)$
            windowrulev2 = opacity 0.8 override 0.8 override, class:^(org.wezfurlong.wezterm)$

            # ### Key bindings
            $mainMod = SUPER
            $altMod = ALT

            bind = $mainMod, Q, killactive, 
            bind = $mainMod, C, exit, 
            # bind = $mainMod, P, pseudo, # dwindle
            bind = $mainMod, J, togglesplit, # dwindle
            bind = $mainMod, M, fullscreen, 1
            bind = $mainMod, F, fullscreen
            bind = $mainMod SHIFT, Space, togglefloating
            bind = $mainMod, X, exec, ${dm-logout}/bin/dm-logout
            bind = $mainMod, P, exec, ${dm-vpn}/bin/dm-vpn
            bind = $mainMod, L, exec, swaylock
            bind = $mainMod CTRL, M, exec, ${toggle-laptop-display}/bin/toggle-laptop-display

            # Apps
            bind = $mainMod, RETURN, exec, kitty --working-directory `${wcwd}/bin/wcwd`
            bind = $mainMod, W, exec, firefox
            bind = $mainMod SHIFT, W, exec, ${dm-firefox-profile}/bin/dm-firefox-profile
            bind = $mainMod, D, exec, ${pkgs.tofi}/bin/tofi-drun
            bind = $mainMod, V, exec, ${pkgs.pavucontrol}/bin/pavucontrol
            bind = $mainMod, E, exec, ${pkgs.xfce.thunar}/bin/thunar
            bind = $mainMod SHIFT, P, exec, ${pkgs.nwg-displays}/bin/nwg-displays
            bind = , Print, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -

            # Move focus with mainMod + left and right arrow
            bind = $mainMod, right, layoutmsg, cyclenext
            bind = $mainMod, left, layoutmsg, cycleprev

            # Layout orientation
            bind = $mainMod, O, layoutmsg, orientationnext
            bind = $mainMod SHIFT, O, layoutmsg, orientationprev
            bind = $mainMod SHIFT, BackSpace, layoutmsg, rollnext

            # Groups
            bind = $mainMod, G, togglegroup
            bind = $mainMod ALT, Right, changegroupactive, f
            bind = $mainMod ALT, Left, changegroupactive, b
            bind = $mainMod ALT SHIFT, Right, movewindoworgroup, r
            bind = $mainMod ALT SHIFT, Left, movewindoworgroup, l

            # Swap windows
            bind = $mainMod SHIFT, right, layoutmsg, swapnext
            bind = $mainMod SHIFT, left, layoutmsg, swapprev

            # Resize windows
            bind = $mainMod CTRL, Left, resizeactive, -40 0
            bind = $mainMod CTRL, Right, resizeactive, 40 0
            bind = $mainMod CTRL, Up, resizeactive, 0 -40
            bind = $mainMod CTRL, Down, resizeactive, 0 40

            # Cycle workspaces
            bind = $mainMod, Tab, workspace, e+1
            bind = $mainMod SHIFT, Tab, workspace, e-1

            # Swap current window with master
            bind = $mainMod, BackSpace, layoutmsg, swapwithmaster auto

            # Brightness
            bind = , XF86MonBrightnessUp, exec, swayosd-client --brightness raise
            bind = , XF86MonBrightnessDown, exec, swayosd-client --brightness lower

            # Speaker volume
            bind = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise
            bind = , XF86AudioLowerVolume, exec, swayosd-client --output-volume lower
            bind = , XF86AudioMute, exec, swayosd-client --output-volume mute-toggle

            # Mic volume
            bind = $mainMod, XF86AudioRaiseVolume, exec, swayosd-client --input-volume raise
            bind = $mainMod, XF86AudioLowerVolume, exec, swayosd-client --input-volume lower
            bind = $mainMod, XF86AudioMute, exec, swayosd-client --input-volume mute-toggle
            
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

            # Focus monitor
            bind = $altMod, 1, focusmonitor, 0
            bind = $altMod, 2, focusmonitor, 1
            bind = $altMod, 3, focusmonitor, 2

            # Move current workspace to monitor
            bind = $altMod SHIFT, 1, movecurrentworkspacetomonitor, 0
            bind = $altMod SHIFT, 2, movecurrentworkspacetomonitor, 1
            bind = $altMod SHIFT, 3, movecurrentworkspacetomonitor, 2

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
        QT_QPA_PLATFORM = "wayland";
        # QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        # QT_QPA_PLATFORM = "wayland;xcb";
        # QT_QPA_PLATFORMTHEME = "qt5ct";
      };
    };

    # Desktop portal
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    environment.systemPackages = with pkgs; [
      hyprpaper
      wl-clipboard
      wlr-randr
      nwg-displays
      hyprland-protocols
      xorg.xlsclients
      # hyprpicker
    ];

    services.gnome.at-spi2-core.enable = true;

    services.displayManager = {
      defaultSession = "hyprland";
      autoLogin = mkIf config.antob.user.autoLogin {
        enable = true;
        user = config.antob.user.name;
      };
    };

    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Enable LightDm display manager.
      displayManager.lightdm.enable = true;
    };
  };
}
