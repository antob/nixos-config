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

  dmsEnabled = config.antob.desktop.addons.dms-shell.enable;
  noctaliaEnabled = config.antob.desktop.addons.noctalia-shell.enable;

  terminal = "${pkgs.kitty}/bin/kitty";
  tmuxTerminal = "${pkgs.kitty}/bin/kitty";
  tuiTerminal = "${pkgs.alacritty}/bin/alacritty";

  dm-vpn =
    if config.antob.services.networkd-vpn.enable then
      lib.getExe (pkgs.callPackage ../scripts/dm-networkd-vpn.nix { inherit config; })
    else
      lib.getExe (pkgs.callPackage ../scripts/dm-nm-vpn.nix { });
  dm-firefox-profile = lib.getExe (
    pkgs.callPackage ../scripts/dm-firefox-profile.nix { inherit config; }
  );
  cmd-cycle-workspace = lib.getExe (pkgs.callPackage ./scripts/cmd-cycle-workspace.nix { });
in
{
  imports = [ inputs.monique.nixosModules.default ];

  options.antob.desktop.niri = with types; {
    enable = mkEnableOption "Enable Niri.";
    mainOutput = mkOpt types.str "eDP-1" "The name of the main output.";
  };

  config = mkIf cfg.enable {
    programs.monique.enable = true;
    programs.niri.enable = true;

    # xdg-desktop-portal-gnome FileChooser call depends on Nautilus
    services.dbus.packages = [ pkgs.nautilus ];

    antob = {
      desktop.addons = {
        gtk = enabled;
        nautilus = enabled;
        noctalia-shell = enabled;
        rofi = {
          enable = true;
          launchPrefix = "niri msg action spawn -- ";
        };
      };

      home.extraOptions = {
        xdg.configFile."niri/config.kdl".text = concatStringsSep "\n" [
          /* kdl */ ''
            input {
              keyboard {
                xkb {
                  layout "se,se"
                  model ""
                  rules ""
                  variant "us,"
                  options "caps:ctrl_modifier,grp:win_space_toggle"
                }
                repeat-delay 200
                repeat-rate 40
                track-layout "global"
              }
              touchpad {
                tap
                dwt
                natural-scroll
              }
              focus-follows-mouse max-scroll-amount="0%"
            }
            screenshot-path "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png"
            prefer-no-csd
            overview { zoom 0.5; }
            layout {
              gaps 16
              struts {
                left 32
                right 32
                top 0
                bottom 0
              }
              focus-ring { off; }
              border {
                width 2
                urgent-color "#${colors.base0F}ff"
                active-color "#${colors.base0C}ff"
                inactive-color "#${colors.base12}aa"
              }
              shadow {
                on
                offset x=0.0 y=5.0
                softness 30.0
                spread 5.0
                draw-behind-window false
                color "#00000070"
              }
              tab-indicator {
                gap 5.0
                width 4
                length total-proportion=0.5
                position "top"
                gaps-between-tabs 10
                corner-radius 2
              }
              insert-hint {
                color "#${colors.base12}88"
              }
              default-column-width {
                proportion 1.0
              }
              preset-column-widths {
                proportion 0.33
                proportion 0.50
                proportion 0.67
                proportion 1.00
              }
              center-focused-column "on-overflow"
              always-center-single-column
            }
            cursor {
              xcursor-theme "${gtkCfg.cursor.name}"
              xcursor-size ${toString gtkCfg.cursor.size}
              hide-when-typing
              hide-after-inactive-ms 5000
            }
            hotkey-overlay { skip-at-startup; }
            environment {
              QT_QPA_PLATFORM "wayland"
              QT_QPA_PLATFORMTHEME "gtk3"
              ELECTRON_OZONE_PLATFORM_HINT "auto"
            }
            window-rule {
              draw-border-with-background false
              geometry-corner-radius 4
              clip-to-geometry true
              opacity 1.0
              open-maximized false
            }
            window-rule {
              match title="Alacritty"
              match app-id="org.wezfurlong.wezterm"
              match app-id="kitty"
              match app-id="com.mitchellh.ghostty"
              opacity 0.90
            }
            window-rule {
              match title="Alacritty"
              match app-id="org.wezfurlong.wezterm"
              match app-id="kitty"
              match app-id="com.mitchellh.ghostty"
              exclude app-id="Alacritty"
              opacity 0.95
            }
            window-rule {
              match app-id="TUI.float"
              match app-id="firefox" title="^Extension:"
              open-floating true
              open-focused true
            }
            window-rule {
              match app-id="TUI.float.lg"
              default-column-width { proportion 0.75; }
              default-window-height { proportion 0.70; }
              open-floating true
              open-focused true
            }
            window-rule {
              match title="meet.google.com is sharing a window."
              default-floating-position relative-to="top" x=0 y=0
            }
            // Apps: blur them all without xray for a better look
            window-rule {
              background-effect {
                blur true
                xray false
              }
            }
            gestures {
              hot-corners {
                off
              }
            }
            xwayland-satellite {
              path "${lib.getExe pkgs.xwayland-satellite}"
            }
            binds {
              // Monitor focus
              Alt+Down { focus-monitor-down; }
              Alt+Up { focus-monitor-up; }
              Alt+Left { focus-monitor-left; }
              Alt+Right { focus-monitor-right; }

              // Workspace focus
              Mod+1 { focus-workspace 1; }
              Mod+2 { focus-workspace 2; }
              Mod+3 { focus-workspace 3; }
              Mod+4 { focus-workspace 4; }
              Mod+5 { focus-workspace 5; }
              Mod+6 { focus-workspace 6; }
              Mod+7 { focus-workspace 7; }
              Mod+8 { focus-workspace 8; }
              "Mod+Page_Down" { focus-workspace-down; }
              "Mod+Page_Up" { focus-workspace-up; }
              Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
              Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
              Alt+Grave { focus-workspace-previous; }
              Mod+Grave { spawn-sh "${cmd-cycle-workspace} forward"; }
              Mod+Shift+Grave { spawn-sh "${cmd-cycle-workspace} backward"; }
              // Workspace move
              Mod+Ctrl+Up { move-workspace-up; }
              Mod+Ctrl+Down { move-workspace-down; }
              Mod+Alt+Up { move-workspace-to-monitor-up; }
              Mod+Alt+Down { move-workspace-to-monitor-down; }
              Mod+Alt+Left { move-workspace-to-monitor-left; }
              Mod+Alt+Right { move-workspace-to-monitor-right; }

              // Column focus
              Mod+Home { focus-column-first; }
              Mod+End { focus-column-last; }
              Mod+Left { focus-column-left; }
              Mod+Right { focus-column-right; }
              Mod+Tab { focus-column-right-or-first; }
              Mod+Shift+Tab { focus-column-left-or-last; }
              // Column move
              Mod+Alt+Shift+Up { move-column-to-monitor-up; }
              Mod+Alt+Shift+Down { move-column-to-monitor-down; }
              Mod+Alt+Shift+Left { move-column-to-monitor-left; }
              Mod+Alt+Shift+Right { move-column-to-monitor-right; }
              Mod+Shift+Left { move-column-left-or-to-monitor-left; }
              Mod+Shift+Right { move-column-right-or-to-monitor-right; }
              Mod+Ctrl+Shift+1 { move-column-to-workspace 1; }
              Mod+Ctrl+Shift+2 { move-column-to-workspace 2; }
              Mod+Ctrl+Shift+3 { move-column-to-workspace 3; }
              Mod+Ctrl+Shift+4 { move-column-to-workspace 4; }
              Mod+Ctrl+Shift+5 { move-column-to-workspace 5; }
              Mod+Ctrl+Shift+6 { move-column-to-workspace 6; }
              Mod+Ctrl+Shift+7 { move-column-to-workspace 7; }
              Mod+Ctrl+Shift+8 { move-column-to-workspace 8; }
              "Mod+Ctrl+Page_Down" { move-column-to-workspace-down; }
              "Mod+Ctrl+Page_Up" { move-column-to-workspace-up; }
              Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
              Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }
              Mod+Ctrl+End { move-column-to-last; }
              Mod+Ctrl+Home { move-column-to-first; }
              Mod+C { center-column; }

              // Window focus
              Alt+Tab { focus-window-previous; }
              Mod+Down { focus-window-or-workspace-down; }
              Mod+Up { focus-window-or-workspace-up; }
              // Window move
              Mod+Shift+1 { move-window-to-workspace 1; }
              Mod+Shift+2 { move-window-to-workspace 2; }
              Mod+Shift+3 { move-window-to-workspace 3; }
              Mod+Shift+4 { move-window-to-workspace 4; }
              Mod+Shift+5 { move-window-to-workspace 5; }
              Mod+Shift+6 { move-window-to-workspace 6; }
              Mod+Shift+7 { move-window-to-workspace 7; }
              Mod+Shift+8 { move-window-to-workspace 8; }
              Mod+Shift+Up { move-window-up-or-to-workspace-up; }
              Mod+Shift+Down { move-window-down-or-to-workspace-down; }
              Mod+Alt+Ctrl+Up { move-window-to-monitor-up; }
              Mod+Alt+Ctrl+Down { move-window-to-monitor-down; }
              Mod+Alt+Ctrl+Left { move-window-to-monitor-left; }
              Mod+Alt+Ctrl+Right { move-window-to-monitor-right; }
              Mod+BracketLeft { consume-or-expel-window-left; }
              Mod+BracketRight { consume-or-expel-window-right; }
              Mod+Period { expel-window-from-column; }
              // Window resize
              Mod+Equal { set-column-width "+10%"; }
              Mod+F { fullscreen-window; }
              Mod+M { maximize-column; }
              Mod+Minus { set-column-width "-10%"; }
              Mod+R { switch-preset-column-width; }
              Mod+Shift+0 { reset-window-height; }
              Mod+Shift+M { expand-column-to-available-width; }
              Mod+Shift+Equal { set-window-height "+10%"; }
              Mod+Shift+Minus { set-window-height "-10%"; }

              // Misc
              Mod+Q repeat=false { close-window; }
              Mod+Shift+Q { quit; }
              Mod+Shift+P { power-off-monitors; }
              Mod+Shift+V { switch-focus-between-floating-and-tiling; }
              Mod+V { toggle-window-floating; }
              Mod+Y { toggle-column-tabbed-display; }

              // Apps & menus
              Mod+O hotkey-overlay-title="Show overview" repeat=false { toggle-overview; }
              Mod+E hotkey-overlay-title="File manger" repeat=false { spawn-sh "nautilus --new-window"; }
              Mod+P hotkey-overlay-title="Show VPN menu" repeat=false { spawn-sh "${dm-vpn}"; }
              Mod+Return hotkey-overlay-title="Terminal (tmux)" repeat=false { spawn "${tmuxTerminal}" "tmux-attach-unused"; }
              Mod+Shift+Return hotkey-overlay-title="Terminal" repeat=false { spawn "${terminal}"; }
              Mod+Shift+Slash hotkey-overlay-title="Show hotkey overlay" repeat=false { show-hotkey-overlay; }
              Mod+Shift+W hotkey-overlay-title="Select Firefox profile" repeat=false { spawn-sh "${dm-firefox-profile}"; }
              Mod+T hotkey-overlay-title="Activity" repeat=false { spawn-sh "${tuiTerminal} --class=TUI.float.lg -e ${lib.getExe pkgs.bottom}"; }
              Mod+W hotkey-overlay-title="Web browser" repeat=false { spawn "firefox"; }
              Mod+Ctrl+E hotkey-overlay-title="Emoji selector" repeat=false { spawn-sh "rofimoji --prompt Emojis --action copy"; }
              Mod+D hotkey-overlay-title="App launcher" repeat=false { spawn-sh "rofi -show drun -show-icons"; }
          ''
          (lib.optionalString dmsEnabled /* kdl */ ''
            // DMS bindings
            XF86AudioRaiseVolume allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "increment" "3"; }
            XF86AudioLowerVolume allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "decrement" "3"; }
            XF86AudioMute allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "mute"; }
            XF86MonBrightnessUp allow-when-locked=true { spawn "dms" "ipc" "call" "brightness" "increment" "5" ""; }
            XF86MonBrightnessDown allow-when-locked=true { spawn "dms" "ipc" "call" "brightness" "decrement" "5" ""; }
            XF86AudioMicMute allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "micmute"; }
            Print { spawn "dms" "ipc" "call" "niri" "screenshot"; }
            Mod+U hotkey-overlay-title="Toggle locking on idle" repeat=false { spawn "dms" "ipc" "call" "inhibit" "toggle"; }
            Mod+X hotkey-overlay-title="System menu" repeat=false { spawn "dms" "ipc" "call" "widget" "toggle" "powerMenuButton"; }
            Super+L hotkey-overlay-title="Lock screen" repeat=false { spawn "dms" "ipc" "call" "lock" "lock"; }
            Super+Comma hotkey-overlay-title="Settings" repeat=false { spawn "dms" "ipc" "call" "settings" "focusOrToggle"; }
          '')
          (lib.optionalString noctaliaEnabled /* kdl */ ''
            // Noctalia bindings
            XF86AudioRaiseVolume { spawn "noctalia-shell" "ipc" "call" "volume" "increase"; }
            XF86AudioLowerVolume { spawn "noctalia-shell" "ipc" "call" "volume" "decrease"; }
            XF86AudioMute { spawn "noctalia-shell" "ipc" "call" "volume" "muteOutput"; }
            XF86MonBrightnessUp { spawn "noctalia-shell" "ipc" "call" "brightness" "increase"; }
            XF86MonBrightnessDown { spawn "noctalia-shell" "ipc" "call" "brightness" "decrease"; }
            XF86AudioMicMute { spawn "noctalia-shell" "ipc" "call" "volume" "muteInput"; }
            Print { spawn-sh "grim -g \"$(slurp)\" - | swappy -f -"; }
            Mod+U hotkey-overlay-title="Toggle locking on idle" repeat=false { spawn "noctalia-shell" "ipc" "call" "idleInhibitor" "toggle"; }
            Mod+B hotkey-overlay-title="Bluetooth" repeat=false { spawn "noctalia-shell" "ipc" "call" "bluetooth" "togglePanel"; }
            Mod+X hotkey-overlay-title="System menu" repeat=false { spawn "noctalia-shell" "ipc" "call" "sessionMenu" "toggle"; }
            Super+L hotkey-overlay-title="Lock screen" repeat=false { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }
            Super+Comma hotkey-overlay-title="Settings" repeat=false { spawn "noctalia-shell" "ipc" "call" "settings" "toggle"; }
            Mod+Ctrl+P hotkey-overlay-title="Display Manager" repeat=false { spawn "monique"; }
          '')
          " }"
          (lib.optionalString dmsEnabled /* kdl */ ''
            // Set the overview wallpaper on the backdrop.
            layer-rule {
              match namespace="dms:blurwallpaper"
              place-within-backdrop true
            }

            // Include DMS settings
            include "dms/outputs.kdl"
          '')
          (lib.optionalString noctaliaEnabled /* kdl */ ''
            // Blur everywhere without xray for a better look
            layer-rule {
              match namespace="^noctalia-(background|launcher-overlay|dock)-.*$"
              background-effect {
                xray false
              }
            }

            // Set the overview wallpaper on the backdrop.
            layer-rule {
              match namespace="^noctalia-overview*"
              place-within-backdrop true
            }

            window-rule {
              match app-id="com.github.monique"
              default-column-width { proportion 0.75; }
              default-window-height { proportion 0.70; }
              open-floating true
              open-focused true
            }

            debug {
              // Allows notification actions and window activation from Noctalia.
              honor-xdg-activation-with-invalid-serial
            }

            // Include DMS settings
            include "monitors.kdl"

            // Launch Noctalia at startup
            spawn-sh-at-startup "noctalia-shell"
          '')
        ];

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

    antob.persistence.home.directories = [
      ".config/niri/dms"
      ".config/monique"
    ];

    # Desktop portal
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };

    environment.systemPackages = with pkgs; [
      gnome-calculator
      imv
      mpv
      jq
      impala
      bluetui
      wiremix
      pamixer
      wayland-utils
      wl-clipboard
      libqalculate
      libnotify
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
  };
}
