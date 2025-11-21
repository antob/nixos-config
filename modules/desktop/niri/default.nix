{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.niri;
  gtkCfg = config.antob.desktop.addons.gtk;
  colors = config.antob.color-scheme.colors;
  osdclient = "${pkgs.swayosd}/bin/swayosd-client --monitor ''$(niri msg -j focused-output | jq -r '.name')";
  dm-system = lib.getExe (pkgs.callPackage ./scripts/dm-system.nix { });
  dm-vpn =
    if config.antob.services.networkd-vpn.enable then
      lib.getExe (pkgs.callPackage ../scripts/dm-networkd-vpn.nix { inherit config; })
    else
      lib.getExe (pkgs.callPackage ../scripts/dm-nm-vpn.nix { });
  dm-firefox-profile = lib.getExe (
    pkgs.callPackage ../scripts/dm-firefox-profile.nix { inherit config; }
  );
  cmd-screenshot = lib.getExe (pkgs.callPackage ../scripts/cmd-screenshot.nix { });
  cmd-annotate = lib.getExe (pkgs.callPackage ./scripts/cmd-annotate.nix { });
  cmd-toggle-swayidle = lib.getExe (pkgs.callPackage ../scripts/cmd-toggle-swayidle.nix { });
in
{
  imports = [ inputs.niri.nixosModules.niri ];

  options.antob.desktop.niri = with types; {
    enable = mkEnableOption "Enable Niri.";
    enableCache = mkEnableOption "Enable Niri build cache.";
    mainOutput = mkOpt types.str "eDP-1" "The name of the main output.";
  };

  config = mkMerge [
    (mkIf cfg.enableCache {
      nix.settings = {
        substituters = [ "https://niri.cachix.org" ];
        trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
      };
    })
    (mkIf cfg.enable {
      nixpkgs.overlays = [ inputs.niri.overlays.niri ];

      programs.niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };

      # xdg-desktop-portal-gnome FileChooser call depends on Nautilus
      services.dbus.packages = [ pkgs.nautilus ];

      antob = {
        services.gammastep = enabled;
        desktop.addons = {
          gtk = enabled;
          nautilus = enabled;
          mako = enabled;
          swayosd = enabled;
          swayidle = enabled;
          waybar = {
            enable = true;
            enableSystemd = true;
          };
          walker = {
            enable = true;
            runAsService = false;
            launchPrefix = "niri msg action spawn -- ";
          };
        };

        home.extraOptions = {
          programs.niri.settings = {
            prefer-no-csd = true;
            hotkey-overlay.skip-at-startup = true;
            # clipboard.disable-primary = true;
            overview.zoom = 0.5;
            screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";
            gestures.hot-corners.enable = false;

            workspaces = {
              "󰬺".open-on-output = cfg.mainOutput;
              "󰬻".open-on-output = cfg.mainOutput;
              "󰬼".open-on-output = cfg.mainOutput;
              "󰬽".open-on-output = cfg.mainOutput;
              "󰬾".open-on-output = cfg.mainOutput;
              "󰬿".open-on-output = cfg.mainOutput;
              "󰭀".open-on-output = cfg.mainOutput;
              "󰭁".open-on-output = cfg.mainOutput;
            };

            animations = {
              workspace-switch.enable = false;
            };

            input = {
              focus-follows-mouse = {
                enable = true;
                max-scroll-amount = "0%";
              };
              keyboard = {
                repeat-delay = 200;
                repeat-rate = 40;

                xkb = {
                  layout = "se,se";
                  variant = "us,";
                  options = "caps:ctrl_modifier,grp:win_space_toggle";
                };
              };
              touchpad = {
                dwt = true;
              };
            };

            cursor = {
              hide-when-typing = true;
              hide-after-inactive-ms = 5000;
              size = gtkCfg.cursor.size;
              theme = gtkCfg.cursor.name;
            };

            outputs = {
              # Internal laptop screen
              eDP-1 = {
                focus-at-startup = true;
                mode = {
                  width = 2256;
                  height = 1504;
                };
                scale = 1.5;
                position = {
                  x = -752;
                  y = 0;
                };
              };

              # Home monitor
              "Acer Technologies XB273U TJ5EE0018521" = {
                mode = {
                  width = 2560;
                  height = 1440;
                };
                scale = 1.0;
                position = {
                  x = -1280;
                  y = -1440;
                };
              };

              # OBIT monitor 1
              "Philips Consumer Electronics Company PHL 49B2U5900 AU02507007832" = {
                mode = {
                  width = 5120;
                  height = 1440;
                };
                scale = 1.0;
                position = {
                  x = -2560;
                  y = -1440;
                };
                # layout.default-column-width.proportion = 2. / 3.;
              };
              # OBIT monitor 2
              "LG Electronics LG HDR DQHD 0x000320C3" = {
                mode = {
                  width = 5120;
                  height = 1440;
                };
                scale = 1.0;
                position = {
                  x = -2560;
                  y = -1440;
                };
              };
            };

            layout = {
              gaps = 16;
              struts.left = 32;
              struts.right = 32;
              always-center-single-column = true;

              # When to center a column when changing focus, options are:
              # - "never", default behavior, focusing an off-screen column will keep at the left
              #   or right edge of the screen.
              # - "always", the focused column will always be centered.
              # - "on-overflow", focusing a column will center it if it doesn't fit
              #   together with the previously focused column.
              center-focused-column = "on-overflow";

              preset-column-widths = [
                { proportion = 1. / 3.; }
                { proportion = 1. / 2.; }
                { proportion = 2. / 3.; }
                { proportion = 1.; }
              ];
              default-column-width.proportion = 1.;

              focus-ring = {
                enable = false;
                width = 3;
                active.color = "#${colors.base0C}ff";
                inactive.color = "#${colors.base12}aa";
              };

              border = {
                enable = true;
                width = 3;
                active.color = "#${colors.base0C}ff";
                inactive.color = "#${colors.base12}aa";
                urgent.color = "#${colors.base0F}ff";
              };

              shadow.enable = true;

              # default-column-display = "tabbed";

              tab-indicator = {
                position = "top";
                gaps-between-tabs = 10;
                hide-when-single-tab = false;
                place-within-column = false;
                width = 4;
                corner-radius = 2;
                # active.color = "#${colors.base0C}ff";
                # inactive.color = "#${colors.base12}aa";
              };

              insert-hint.display.color = "#${colors.base12}88";
            };

            window-rules = [
              # Default appearance for all windows
              {
                opacity = 1.0;
                draw-border-with-background = false;
                geometry-corner-radius =
                  let
                    r = 8.0;
                  in
                  {
                    top-left = r;
                    top-right = r;
                    bottom-left = r;
                    bottom-right = r;
                  };
                clip-to-geometry = true;
              }

              # Transparent windows
              {
                opacity = 0.9;
                matches = [
                  { title = "Alacritty"; }
                ];
              }
              {
                opacity = 0.95;
                matches = [
                  { title = "Alacritty"; }
                ];
                excludes = [
                  { app-id = "Alacritty"; }
                ];
              }
              # Floating windows
              {
                matches = [
                  { app-id = "TUI.float"; }
                  {
                    app-id = "firefox";
                    title = "^Extension:";
                  }
                  { app-id = "Wiremix"; }
                  { app-id = ".blueman-manager-wrapped"; }
                ];
                open-floating = true;
                open-focused = true;
              }
              {
                matches = [
                  { app-id = "TUI.float.lg"; }
                  { title = "satty"; }
                  {
                    app-id = "thunderbird";
                    title = "Message Filters|Activity Manager";
                  }
                ];
                open-floating = true;
                open-focused = true;
                default-window-height.proportion = 0.7;
                default-column-width.proportion = 0.75;
              }

              {
                open-on-workspace = "󰬻";
                open-focused = true;
                matches = [ { app-id = "firefox"; } ];
              }
              {
                open-on-workspace = "󰬼";
                open-focused = true;
                matches = [ { app-id = "code"; } ];
              }
              {
                open-on-workspace = "󰬾";
                open-focused = true;
                matches = [
                  { app-id = "obsidian"; }
                  { app-id = "chrome-app.slack.com"; }
                  { app-id = "chrome-teams.microsoft.com"; }
                  { app-id = "chrome-meet.google.com"; }
                  { app-id = "thunderbird"; }
                ];
              }

              ## Specific fixes
              # Move Google Meet sharing dialog to center top
              {
                matches = [ { title = "meet.google.com is sharing a window."; } ];
                default-floating-position = {
                  relative-to = "top";
                  x = 0;
                  y = 0;
                };
              }
            ];

            xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite-unstable}";

            spawn-at-startup = [
              {
                sh = "swaybg --mode fill --image /home/tob/Pictures/Wallpapers/Omarchy-Backgrounds/1-scenery-pink-lakeside-sunset-lake-landscape-scenic-panorama-7680x3215-144.png";
              }
              {
                sh = "walker --gapplication-service";
              }
              {
                sh = "${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit";
              }
            ];

            binds =
              with config.home-manager.users.${config.antob.user.name}.lib.niri.actions;
              let
                mod = "Mod";
              in
              {
                "${mod}+Shift+Slash" = {
                  action = show-hotkey-overlay;
                  hotkey-overlay.title = "Show hotkey overlay";
                  repeat = false;
                };
                "${mod}+Return" = {
                  action = spawn-sh (
                    if config.antob.cli-apps.tmux.enable then "alacritty -e tmux-attach-unused" else "alacritty"
                  );
                  hotkey-overlay.title = "Terminal (tmux)";
                  repeat = false;
                };
                "${mod}+Shift+Return" = {
                  action = spawn "alacritty";
                  hotkey-overlay.title = "Terminal (no tmux)";
                  repeat = false;
                };
                "${mod}+W" = {
                  action = spawn "firefox";
                  hotkey-overlay.title = "Web browser";
                  repeat = false;
                };
                "${mod}+E" = {
                  action = spawn-sh "nautilus --new-window";
                  hotkey-overlay.title = "File manger";
                  repeat = false;
                };
                "Super+L" = {
                  action = spawn "sh" "-c" "loginctl lock-session && niri msg action power-off-monitors";
                  hotkey-overlay.title = "Lock screen";
                  repeat = false;
                };

                "${mod}+B" = {
                  action = spawn-sh "alacritty --class=TUI.float -e bluetui";
                  hotkey-overlay.title = "Bluetooth";
                  repeat = false;
                };

                "${mod}+T" = {
                  action = spawn-sh "alacritty --class=TUI.float.lg -e ${lib.getExe pkgs.bottom}";
                  hotkey-overlay.title = "Activity";
                  repeat = false;
                };

                # Open/close the Overview: a zoomed-out view of workspaces and windows.
                "${mod}+O" = {
                  action = toggle-overview;
                  hotkey-overlay.title = "Show overview";
                  repeat = false;
                };

                "${mod}+Q" = {
                  action = close-window;
                  repeat = false;
                };

                # Menues
                "${mod}+D" = {
                  action = spawn-sh "walker -p 'Start…'";
                  hotkey-overlay.title = "App launcher";
                  repeat = false;
                };
                "${mod}+X" = {
                  action = spawn-sh "${dm-system}";
                  hotkey-overlay.title = "System menu";
                  repeat = false;
                };
                "${mod}+Shift+W" = {
                  action = spawn-sh "${dm-firefox-profile}";
                  hotkey-overlay.title = "Select Firefox profile";
                  repeat = false;
                };
                "${mod}+P" = {
                  action = spawn-sh "${dm-vpn}";
                  hotkey-overlay.title = "Show VPN menu";
                  repeat = false;
                };
                "${mod}+Ctrl+E" = {
                  action = spawn-sh "walker -m Emojis";
                  hotkey-overlay.title = "Emoji selector";
                  repeat = false;
                };

                # Focus column/window
                "${mod}+Left".action = focus-column-left;
                "${mod}+Down".action = focus-window-down;
                "${mod}+Up".action = focus-window-up;
                "${mod}+Right".action = focus-column-right;
                "${mod}+Home".action = focus-column-first;
                "${mod}+End".action = focus-column-last;

                "Alt+Tab".action = focus-window-previous;

                # Move column/window
                "${mod}+Shift+Left".action = move-column-left-or-to-monitor-left;
                "${mod}+Shift+Right".action = move-column-right-or-to-monitor-right;

                "${mod}+Shift+Down".action = move-window-down-or-to-workspace-down;
                "${mod}+Shift+Up".action = move-window-up-or-to-workspace-up;
                "${mod}+Ctrl+Home".action = move-column-to-first;
                "${mod}+Ctrl+End".action = move-column-to-last;

                # Focus monitor
                "${mod}+Alt+Left".action = focus-monitor-left;
                "${mod}+Alt+Down".action = focus-monitor-down;
                "${mod}+Alt+Up".action = focus-monitor-up;
                "${mod}+Alt+Right".action = focus-monitor-right;

                # Move workspace to monitor
                "${mod}+Alt+Home".action = move-workspace-to-monitor-left;
                "${mod}+Alt+Page_Down".action = move-workspace-to-monitor-down;
                "${mod}+Alt+Page_Up".action = move-workspace-to-monitor-up;
                "${mod}+Alt+End".action = move-workspace-to-monitor-right;

                # Move column to monitor
                "${mod}+Alt+Shift+Left".action = move-column-to-monitor-left;
                "${mod}+Alt+Shift+Down".action = move-column-to-monitor-down;
                "${mod}+Alt+Shift+Up".action = move-column-to-monitor-up;
                "${mod}+Alt+Shift+Right".action = move-column-to-monitor-right;

                # Move window to monitor
                "${mod}+Alt+Ctrl+Left".action = move-window-to-monitor-left;
                "${mod}+Alt+Ctrl+Down".action = move-window-to-monitor-down;
                "${mod}+Alt+Ctrl+Up".action = move-window-to-monitor-up;
                "${mod}+Alt+Ctrl+Right".action = move-window-to-monitor-right;

                # Focus workspace
                "${mod}+Grave".action = focus-workspace-down;
                "${mod}+Shift+Grave".action = focus-workspace-up;
                "${mod}+Page_Down".action = focus-workspace-down;
                "${mod}+Page_Up".action = focus-workspace-up;

                # Move column to workspace
                "${mod}+Ctrl+Page_Down".action = move-column-to-workspace-down;
                "${mod}+Ctrl+Page_Up".action = move-column-to-workspace-up;

                # // Alternatively, there are commands to move just a single window:
                # // ${mod}+Ctrl+Page_Down { move-window-to-workspace-down; }
                # // ...

                # Move workspace up or down
                "${mod}+Shift+Page_Down".action = move-workspace-down;
                "${mod}+Shift+Page_Up".action = move-workspace-up;

                # // You can bind mouse wheel scroll ticks using the following syntax.
                # // These binds will change direction based on the natural-scroll setting.
                # //
                # // To avoid scrolling through workspaces really fast, you can use
                # // the cooldown-ms property. The bind will be rate-limited to this value.
                # // You can set a cooldown on any bind, but it's most useful for the wheel.
                "${mod}+WheelScrollDown" = {
                  action = focus-workspace-down;
                  cooldown-ms = 150;
                };
                "${mod}+WheelScrollUp" = {
                  action = focus-workspace-up;
                  cooldown-ms = 150;
                };
                "${mod}+Ctrl+WheelScrollDown" = {
                  action = move-column-to-workspace-down;
                  cooldown-ms = 150;
                };
                "${mod}+Ctrl+WheelScrollUp" = {
                  action = move-column-to-workspace-up;
                  cooldown-ms = 150;
                };

                # Shortcuts for named workspaces
                "${mod}+1".action = focus-workspace "󰬺";
                "${mod}+2".action = focus-workspace "󰬻";
                "${mod}+3".action = focus-workspace "󰬼";
                "${mod}+4".action = focus-workspace "󰬽";
                "${mod}+5".action = focus-workspace "󰬾";
                "${mod}+6".action = focus-workspace "󰬿";
                "${mod}+7".action = focus-workspace "󰭀";
                "${mod}+8".action = focus-workspace "󰭁";

                "${mod}+Shift+1".action.move-window-to-workspace = "󰬺";
                "${mod}+Shift+2".action.move-window-to-workspace = "󰬻";
                "${mod}+Shift+3".action.move-window-to-workspace = "󰬼";
                "${mod}+Shift+4".action.move-window-to-workspace = "󰬽";
                "${mod}+Shift+5".action.move-window-to-workspace = "󰬾";
                "${mod}+Shift+6".action.move-window-to-workspace = "󰬿";
                "${mod}+Shift+7".action.move-window-to-workspace = "󰭀";
                "${mod}+Shift+8".action.move-window-to-workspace = "󰭁";

                # The wonky format used here is to work-around https://github.com/sodiboo/niri-flake/issues/944
                "${mod}+Ctrl+Shift+1".action.move-column-to-workspace = [ "󰬺" ];
                "${mod}+Ctrl+Shift+2".action.move-column-to-workspace = [ "󰬻" ];
                "${mod}+Ctrl+Shift+3".action.move-column-to-workspace = [ "󰬼" ];
                "${mod}+Ctrl+Shift+4".action.move-column-to-workspace = [ "󰬽" ];
                "${mod}+Ctrl+Shift+5".action.move-column-to-workspace = [ "󰬾" ];
                "${mod}+Ctrl+Shift+6".action.move-column-to-workspace = [ "󰬿" ];
                "${mod}+Ctrl+Shift+7".action.move-column-to-workspace = [ "󰭀" ];
                "${mod}+Ctrl+Shift+8".action.move-column-to-workspace = [ "󰭁" ];

                "${mod}+Comma".action = consume-window-into-column;
                "${mod}+Period".action = expel-window-from-column;

                # There are also commands that consume or expel a single window to the side.
                "${mod}+BracketLeft".action = consume-or-expel-window-left;
                "${mod}+BracketRight".action = consume-or-expel-window-right;

                # Resize columns
                "${mod}+R".action = switch-preset-column-width;
                "${mod}+Shift+0".action = reset-window-height;
                "${mod}+M".action = maximize-column;
                "${mod}+Shift+M".action = expand-column-to-available-width;
                "${mod}+F".action = fullscreen-window;
                "${mod}+C".action = center-column;

                # // Finer width adjustments.
                # // This command can also:
                # // * set width in pixels: "1000"
                # // * adjust width in pixels: "-5" or "+5"
                # // * set width as a percentage of screen width: "25%"
                # // * adjust width as a percentage of screen width: "-10%" or "+10%"
                # // Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
                # // set-column-width "100" will make the column occupy 200 physical screen pixels.
                "${mod}+Minus".action = set-column-width "-10%";
                "${mod}+Equal".action = set-column-width "+10%";

                # // Finer height adjustments when in column with other windows.
                "${mod}+Shift+Minus".action = set-window-height "-10%";
                "${mod}+Shift+Equal".action = set-window-height "+10%";

                # // Move the focused window between the floating and the tiling layout.
                "${mod}+V".action = toggle-window-floating;
                "${mod}+Shift+V".action = switch-focus-between-floating-and-tiling;

                # // Toggle tabbed column display mode.
                # // Windows in this column will appear as vertical tabs,
                # // rather than stacked on top of each other.
                "${mod}+Y".action = toggle-column-tabbed-display;

                "${mod}+A" = {
                  action = spawn-sh "${cmd-annotate}";
                  hotkey-overlay.title = "Annotate image in clipboard";
                };
                "${mod}+U" = {
                  action = spawn-sh "${cmd-toggle-swayidle}";
                  hotkey-overlay.title = "Toggle locking on idle";
                };
                "Print" = {
                  action = spawn-sh "${cmd-screenshot}";
                  hotkey-overlay.title = "Screenshot of region";
                };
                "Shift+Print" = {
                  action = screenshot-window;
                  hotkey-overlay.title = "Screenshot of active window";
                };
                "Alt+Print" = {
                  # Action `screenshot-screen` not supported in `niri-flake`.
                  action = spawn-sh "niri msg action screenshot-screen";
                  hotkey-overlay.title = "Screenshot of active screen";
                };

                # // The quit action will show a confirmation dialog to avoid accidental exits.
                "${mod}+Shift+Q".action = quit;

                # // Powers off the monitors. To turn them back on, do any input like
                # // moving the mouse or pressing any other key.
                "${mod}+Shift+P".action = power-off-monitors;

                # Brightneww controls
                XF86MonBrightnessUp = {
                  action = spawn-sh "${osdclient} --brightness raise";
                  hotkey-overlay.title = "Brightness up";
                };
                XF86MonBrightnessDown = {
                  action = spawn-sh "${osdclient} --brightness lower";
                  hotkey-overlay.title = "Brightness down";
                };
                "Alt+XF86MonBrightnessUp" = {
                  action = spawn-sh "${osdclient} --brightness +1";
                  hotkey-overlay.title = "Brightness up precise";
                };
                "Alt+XF86MonBrightnessDown" = {
                  action = spawn-sh "${osdclient} --brightness -1";
                  hotkey-overlay.title = "Brightness down precise";
                };

                # Volume controls
                XF86AudioRaiseVolume = {
                  action = spawn-sh "${osdclient} --output-volume raise";
                  hotkey-overlay.title = "Volume up";
                  allow-when-locked = true;
                };
                XF86AudioLowerVolume = {
                  action = spawn-sh "${osdclient} --output-volume lower";
                  hotkey-overlay.title = "Volume down";
                  allow-when-locked = true;
                };
                "Alt+XF86AudioRaiseVolume" = {
                  action = spawn-sh "${osdclient} --output-volume +1";
                  hotkey-overlay.title = "Volume up precise";
                  allow-when-locked = true;
                };
                "Alt+XF86AudioLowerVolume" = {
                  action = spawn-sh "${osdclient} --output-volume -1";
                  hotkey-overlay.title = "Volume down precise";
                  allow-when-locked = true;
                };
                XF86AudioMute = {
                  action = spawn-sh "${osdclient} --output-volume mute-toggle";
                  hotkey-overlay.title = "Mute";
                  allow-when-locked = true;
                };
                XF86AudioMicMute = {
                  action = spawn-sh "${osdclient} --input-volume ute-toggle";
                  hotkey-overlay.title = "Mute microphone";
                  allow-when-locked = true;
                };
              };

            environment = {
              ELECTRON_OZONE_PLATFORM_HINT = "wayland";
              NIXOS_OZONE_WL = "1";
              QT_QPA_PLATFORMTHEME = "qt6ct";
              QT_QPA_PLATFORM = "wayland;xcb";
              QT_STYLE_OVERRIDE = "kvantum";
              SDL_VIDEODRIVER = "wayland";
              MOZ_ENABLE_WAYLAND = "1";
              OZONE_PLATFORM = "wayland";
            };
          };

          dconf.settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = gtkCfg.theme.name;
              cursor-theme = gtkCfg.cursor.name;
              cursor-size = gtkCfg.cursor.size;
            };
          };
        };

      };

      environment.systemPackages = with pkgs; [
        gnome-calculator
        imv
        mpv
        sushi
        brightnessctl
        swayosd
        jq
        impala
        bluetui
        wiremix
        pamixer
        swaybg
        xwayland-satellite-unstable
        wayland-utils
        wl-clipboard
        libqalculate
      ];

      services.displayManager = {
        autoLogin = {
          enable = config.antob.user.autoLogin;
          user = config.antob.user.name;
        };
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
    })
  ];
}
