{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.antob;
let
  cfg = config.antob.desktop.gnome;
  colors = config.antob.color-scheme.colors;

  cursorTheme = "Bibata-Modern-Ice";
  cursorSize = 16;
in
{
  options.antob.desktop.gnome = with types; {
    enable = mkEnableOption "Enable Gnome Desktop.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnome-tweaks
      adwaita-icon-theme
      bibata-cursors
      gnomeExtensions.just-perfection
      inputs.paperwm.packages.${pkgs.system}.default
      # gnomeExtensions.tactile
      gnomeExtensions.switcher
      gnomeExtensions.vitals
      gnomeExtensions.caffeine
      gnomeExtensions.hide-cursor
      antob.gnome-shell-extension-workspaces-by-open-apps
      antob.gnome-shell-extension-expand-shutdown-menu
    ];

    services.udev.packages = with pkgs; [ gnome-settings-daemon ];

    antob.system.env = {
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      XCURSOR_THEME = cursorTheme;
      XCURSOR_SIZE = builtins.toString cursorSize;
    };

    # Desktop additions
    antob.desktop.addons = {
      keyring = enabled;
    };

    # Apps
    antob.apps.flameshot = enabled;

    # Desktop portal
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    };

    # GTK config (specific for Gnome)
    antob.home.extraOptions.gtk = {
      enable = true;
      cursorTheme = {
        name = cursorTheme;
        size = cursorSize;
        package = pkgs.bibata-cursors;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-error-bell = false;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-error-bell = false;
      };
    };

    # dconf and xfconf settings
    antob.home.extraOptions = {
      # Default mime apps
      xdg.mimeApps.defaultApplications = {
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
      };

      # xsession.enable = true;

      # Fix for "org.freedesktop.systemd1.NoSuchUnit: Unit tray.target not found."
      # when restarting home manager. See https://github.com/nix-community/home-manager/issues/2064
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      dconf.settings =
        let
          inherit (lib.gvariant) mkTuple mkUint32;
        in
        {
          "org/gnome/shell" = {
            disable-user-extensions = false;

            # `gnome-extensions list` for a list
            enabled-extensions = [
              "paperwm@paperwm.github.com"
              "just-perfection-desktop@just-perfection"
              # "tactile@lundal.io"
              # "switcher@landau.fi"
              "hide-cursor@elcste.com"
              "expand-shutdown-menu@antob.se"
              "Vitals@CoreCoding.com"
              "caffeine@patapon.info"
              "workspaces-by-open-apps@favo02.github.com"
            ];
          };

          ## Extensions configuration
          "org/gnome/shell/extensions/switcher" = {
            fade-enable = true;
            font-size = mkUint32 18;
            icon-size = mkUint32 20;
            matching = 1;
            max-width-percentage = mkUint32 40;
            show-switcher = [ "<Super>d" ];
          };
          "org/gnome/shell/extensions/paperwm" = {
            maximize-within-tiling = false;
            gesture-enabled = false;
            selection-border-size = 5;
            selection-border-radius-bottom = 12;
            show-focus-mode-icon = false;
            show-open-position-icon = false;
            show-window-position-bar = false;
            show-workspace-indicator = false;
            use-default-background = true;
            vertical-margin = 10;
            vertical-margin-bottom = 10;
            disable-topbar-styling = true;
            disable-scratch-in-overview = true;
            topbar-mouse-scroll-enable = false;
            animation-time = 0;
            minimap-scale = 0.0;
            edge-preview-enable = false;
            edge-preview-click-enable = false;

            winprops = [
              ''
                {"wm_class":"firefox","preferredWidth":"100%","spaceIndex":1,"focus":true}
              ''
              ''
                {"wm_class":"chromium-browser","preferredWidth":"100%","spaceIndex":1,"focus":true}
              ''
              ''
                {"wm_class":"codium","preferredWidth":"100%","spaceIndex":2,"focus":true}
              ''
              ''
                {"wm_class":"code","preferredWidth":"100%","spaceIndex":2,"focus":true}
              ''
              ''
                {"wm_class":"obsidian","preferredWidth":"100%","spaceIndex":4,"focus":true}
              ''
              ''
                {"wm_class":"Slack","preferredWidth":"100%","spaceIndex":4,"focus":true}
              ''
              ''
                {"wm_class":"discord","preferredWidth":"100%","spaceIndex":4,"focus":true}
              ''
            ];
          };
          "org/gnome/shell/extensions/paperwm/keybindings" = {
            close-window = [ "<Super>q" ];
            new-window = [ "<Super>n" ];
            switch-left = [ "" ];
            switch-left-loop = [ "<Super>Left" ];
            switch-right = [ "" ];
            switch-right-loop = [ "<Super>Right" ];
            switch-previous = [ "" ];
            switch-next = [ "" ];
            switch-up-workspace = [ "" ];
            switch-down-workspace = [ "" ];
            switch-up-workspace-from-all-monitors = [ "<Super>Page_Up" ];
            switch-down-workspace-from-all-monitors = [ "<Super>Page_Down" ];

            switch-monitor-above = [ "<Alt>Up" ];
            switch-monitor-below = [ "<Alt>Down" ];
            switch-monitor-left = [ "" ];
            switch-monitor-right = [ "" ];
            swap-monitor-above = [ "" ];
            swap-monitor-below = [ "" ];
            swap-monitor-right = [ "" ];
            swap-monitor-left = [ "" ];

            move-monitor-above = [ "<Super><Shift>Up" ];
            move-monitor-below = [ "<Super><Shift>Down" ];
            move-monitor-left = [ "" ];
            move-monitor-right = [ "" ];

            move-space-monitor-above = [ "<Alt><Super>Up" ];
            move-space-monitor-below = [ "<Alt><Super>Down" ];
            move-space-monitor-left = [ "<Alt><Super>Left" ];
            move-space-monitor-right = [ "<Alt><Super>Right" ];

            move-left = [ "<Shift><Super>Left" ];
            move-right = [ "<Shift><Super>Right" ];
            move-up = [ "" ];
            move-down = [ "" ];
          };
          "org/gnome/shell/extensions/caffeine" = {
            show-indicator = "only-active";
            toggle-shortcut = [ "<Super>u" ];
          };
          "org/gnome/shell/extensions/vitals" = {
            show-voltage = false;
            show-fan = false;
            show-battery = true;
            include-public-ip = true;
            hot-sensors = [
              "_memory_usage_"
              "_battery_rate_"
              "_processor_usage_"
            ];
          };
          "org/gnome/shell/extensions/just-perfection" = {
            activities-button = false; # Show workspaces-indicator-by-open-apps instead
            clock-menu = true;
            clock-menu-position = 1; # 0 = Center, 1 = Right, 2 = Left
            clock-menu-position-offset = 8;
            keyboard-layout = false;
            accessibility-menu = false;
            quick-settings-dark-mode = false;
            world-clock = false;
            weather = false;
            calendar = true;
            event-button = false;
            dash = false;
            workspace-popup = false;
            workspaces-in-app-grid = true;
            ripple-box = false;
            window-demands-attention-focus = true;
            window-maximized-on-create = false;
            overlay-key = false;
            switcher-popup-delay = false;
            startup-status = 0; # 0 = Desktop, 1 = Overview
            animation = 0; # Animation speed 1 - 7
          };
          "org/gnome/shell/extensions/workspaces-indicator-by-open-apps" = {
            scroll-enable = false;
            scroll-wraparound = false;
            middle-click-close-app = false;
            click-on-focus-minimize = false;
            indicator-round-borders = false;
            indicator-show-focused-app = false;
            icons-group = "GROUP WITHOUT COUNT";
            icons-limit = 3;
            apps-inactive-effect = "NOTHING";
            apps-minimized-effect = "NOTHING";
            apps-all-desaturate = false;
            size-app-icon = 16;
            size-labels = 14;
            spacing-label-left = 3;
            spacing-label-bottom = 1;
            hide-activities-button = true;
          };

          ## Gnome shell configuration
          "org/gnome/shell/keybindings" = {
            # Remove the default hotkeys for opening favorited applications.
            switch-to-application-1 = [ ];
            switch-to-application-2 = [ ];
            switch-to-application-3 = [ ];
            switch-to-application-4 = [ ];
            switch-to-application-5 = [ ];
            switch-to-application-6 = [ ];
            switch-to-application-7 = [ ];
            switch-to-application-8 = [ ];
            switch-to-application-9 = [ ];
            show-screenshot-ui = [ ];
            toggle-overview = [ "<Shift><Super>d" ];
            toggle-application-view = [ "<Super>d" ];
          };
          "org/gnome/desktop/sound" = {
            event-sounds = false;
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/geometrics-l.jxl";
            picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/geometrics-d.jxl";
            primary-color = "#26a269";
          };
          "org/gnome/desktop/screensaver" = {
            picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/geometrics-l.jxl";
            primary-color = "#26a269";
          };
          "org/gnome/desktop/peripherals/keyboard" = {
            delay = mkUint32 200;
            repeat-interval = mkUint32 40;
          };
          "org/gnome/desktop/peripherals/touchpad" = {
            tap-to-click = true;
            two-finger-scrolling-enabled = true;
          };
          "org/gnome/desktop/peripherals/mouse" = {
            speed = 0.25;
          };
          "org/gnome/desktop/input-sources" = {
            sources = [
              (mkTuple [
                "xkb"
                "se+us"
              ])
            ];
          };
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            accent-color = "teal";
            enable-hot-corners = false;
            show-battery-percentage = true;
            cursor-size = cursorSize;
            text-scaling-factor = 1.0;
            font-hinting = "medium";
            clock-show-weekday = true;
            clock-show-weekdate = true;
            enable-animations = false;
          };
          # "org/gnome/mutter" = {
          #   workspaces-only-on-primary = true;
          # };
          # "org/gnome/mutter/keybindings" = {
          #   toggle-tiled-left = [ ];
          #   toggle-tiled-right = [ ];
          # };
          "org/gnome/shell/app-switcher" = {
            current-workspace-only = true;
          };
          "org/gnome/desktop/wm/preferences" = {
            workspace-names = [ "Main" ];
            button-layout = ":close";
            num-workspaces = 8;
            mouse-button-modifier = "";
          };
          "org/gnome/desktop/wm/keybindings" = {
            switch-to-workspace-1 = [ "<Super>1" ];
            switch-to-workspace-2 = [ "<Super>2" ];
            switch-to-workspace-3 = [ "<Super>3" ];
            switch-to-workspace-4 = [ "<Super>4" ];
            switch-to-workspace-5 = [ "<Super>5" ];
            switch-to-workspace-6 = [ "<Super>6" ];
            switch-to-workspace-7 = [ "<Super>7" ];
            switch-to-workspace-8 = [ "<Super>8" ];
            switch-to-workspace-9 = [ "<Super>9" ];

            move-to-workspace-1 = [ "<Shift><Super>1" ];
            move-to-workspace-2 = [ "<Shift><Super>2" ];
            move-to-workspace-3 = [ "<Shift><Super>3" ];
            move-to-workspace-4 = [ "<Shift><Super>4" ];
            move-to-workspace-5 = [ "<Shift><Super>5" ];
            move-to-workspace-6 = [ "<Shift><Super>6" ];
            move-to-workspace-7 = [ "<Shift><Super>7" ];
            move-to-workspace-8 = [ "<Shift><Super>8" ];
            move-to-workspace-9 = [ "<Shift><Super>9" ];

            # cycle-windows = [ "<Super>Right" ];
            # cycle-windows-backward = [ "<Super>Left" ];

            # toggle-fullscreen = [ "<Super>f" ];
            # close = [ "<Super>q" ];
          };
          "org/gnome/settings-daemon/plugins/color" = {
            night-light-enabled = true;
          };
          "org/gnome/settings-daemon/plugins/power" = {
            ambient-enabled = false;
          };
          # Reserve custom keybinding locations
          "org/gnome/settings-daemon/plugins/media-keys" = {
            custom-keybindings = [
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
            ];
          };
          # Set custom keybindings
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<Super>w";
            command = "firefox";
            name = "Firefox";
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
            binding = "<Super>Return";
            command =
              if config.antob.cli-apps.tmux.enable then "alacritty -e tmux-attach-unused" else "alacritty";
            name = "Alacritty";
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
            binding = "<Super>comma";
            command = "gnome-control-center";
            name = "Settings";
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
            binding = "<Super>e";
            command = "nautilus";
            name = "Files";
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
            binding = "Print";
            command = "flameshot-gui";
            name = "Flameshot";
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
            binding = "<Super><Shift>Return";
            command = "alacritty";
            name = "Alacritty";
          };
          "system/locale" = {
            region = "sv_SE.UTF-8";
          };
          "org/gnome/nm-applet" = {
            disable-connected-notifications = true;
            disable-disconnected-notifications = true;
          };
        };

      # PaperWM style override
      # See default styles: https://github.com/paperwm/PaperWM/blob/release/config/user.css
      xdg.configFile."paperwm/user.css".text = ''
        .paperwm-selection {
          border-radius: 6px !important;
          background-color: transparent;
          border: 3px solid #${colors.base0C};
        }
      '';
    };

    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Configure keymap in X11
      xkb = {
        layout = "se,se";
        variant = "us,";
        options = "caps:ctrl_modifier,grp:win_space_toggle";
      };

      # Configure Set console typematic delay and rate in X11
      autoRepeatDelay = 200;
      autoRepeatInterval = 40;

      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
          autoSuspend = true;
        };
      };
      desktopManager.gnome.enable = true;
    };

    services.libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = true;
        naturalScrolling = true;
      };
    };

    services.displayManager.autoLogin = mkIf config.antob.user.autoLogin {
      enable = true;
      user = config.antob.user.name;
    };

    systemd.services = mkIf config.antob.user.autoLogin {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };

    services.gnome = {
      core-os-services.enable = true;
      core-shell.enable = true;
      core-utilities.enable = true;
      core-developer-tools.enable = true;
      games.enable = false;
      localsearch.enable = false;
      tinysparql.enable = false;
    };

    environment.gnome.excludePackages = with pkgs; [
      gnome-photos
      gnome-tour
      gedit # text editor
      cheese # webcam tool
      epiphany # web browser
      geary # email reader
      yelp # Help view
      gnome-music
      gnome-characters
      gnome-contacts
      gnome-initial-setup
    ];

    antob.persistence.home.files = [ ".config/monitors.xml" ];
  };
}
