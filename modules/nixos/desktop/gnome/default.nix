{ config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.gnome;
  gtkCfg = config.antob.desktop.addons.gtk;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.desktop.gnome = with types; {
    enable = mkEnableOption "Enable Gnome Desktop.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnome.gnome-tweaks
      gnome.adwaita-icon-theme
      gnomeExtensions.appindicator
      gnomeExtensions.paperwm
      gnomeExtensions.switcher
      gnomeExtensions.vitals
      gnomeExtensions.disable-workspace-switcher
      # gnomeExtensions.move-clock
      antob.gnome-shell-extension-instantworkspaceswitcher
      antob.gnome-shell-extension-expand-shutdown-menu
      antob.gnome-extension-remove-accessibility-menu
      bibata-cursors
    ];

    services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

    antob.system.env = {
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Desktop additions
    antob.desktop.addons = {
      keyring = enabled;
    };

    # Desktop portal
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    };

    # GTK config (specific for Gnome)
    antob.home.extraOptions.gtk = {
      enable = true;
      cursorTheme = {
        name = "Bibata-Modern-Ice";
        size = 16;
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
      # xsession.enable = true;

      dconf.settings = let inherit (lib.gvariant) mkTuple mkUint32 mkVariant; in {
        "org/gnome/shell" = {
          disable-user-extensions = false;

          # `gnome-extensions list` for a list
          enabled-extensions = [
            "paperwm@paperwm.github.com"
            "switcher@landau.fi"
            "instantworkspaceswitcher@amalantony.net"
            "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
            "disable-workspace-switcher@jbradaric.me"
            "appindicatorsupport@rgcjonas.gmail.com"
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
            "no-overview@fthx"
            "expand-shutdown-menu@antob.se"
            "remove-accessibility-menu@antob.se"
            "Vitals@CoreCoding.com"
            "Move_Clock@rmy.pobox.com"
          ];
        };
        "org/gnome/shell/extensions/switcher" = {
          fade-enable = true;
          font-size = mkUint32 18;
          icon-size = mkUint32 20;
          matching = 1;
          max-width-percentage = mkUint32 40;
          show-switcher = [ "<Super>d" ];
        };
        "org/gnome/shell/extensions/paperwm" = {
          gesture-enabled = false;
          selection-border-size = 5;
          show-focus-mode-icon = false;
          show-window-position-bar = false;
          show-workspace-indicator = false;
          use-default-background = true;
          vertical-margin = 10;
          vertical-margin-bottom = 10;
          disable-topbar-styling = true;
          animation-time = 0;
          winprops = [
            ''
              {"wm_class":"firefox","preferredWidth":"100%"}
            ''
            ''
              {"wm_class":"VSCodium","preferredWidth":"100%"}
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
        };
        "org/gnome/shell/extensions/auto-move-windows" = {
          application-list = [
            "firefox.desktop:2"
            "chromium-browser.desktop:2"
            "codium.desktop:3"
            "code.desktop:3"
            "slack.desktop:5"
          ];
        };
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
        };
        "org/gnome/desktop/sound" = {
          event-sounds = false;
        };
        "org/gnome/desktop/background" = {
          picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/blobs-l.svg";
          picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/blobs-d.svg";
          primary-color = "#241f31";
        };
        "org/gnome/desktop/screensaver" = {
          picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/blobs-l.svg";
          primary-color = "#241f31";
        };
        "org/gnome/desktop/peripherals/keyboard" = {
          delay = mkUint32 200;
          repeat-interval = mkUint32 40;
        };
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
          two-finger-scrolling-enabled = true;
        };
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          enable-hot-corners = false;
          show-battery-percentage = true;
          cursor-size = 16;
        };
        "org/gnome/desktop/wm/preferences" = {
          workspace-names = [ "Main" ];
          button-layout = ":minimize,maximize,close";
          num-workspaces = 8;
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
        };
        "org/gnome/settings-daemon/plugins/color" = {
          night-light-enabled = true;
        };
        "org/gnome/settings-daemon/plugins/power" = {
          ambient-enabled = false;
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>w";
          command = "firefox";
          name = "Firefox";
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          binding = "<Super>Return";
          command = "kitty";
          name = "Kitty";
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
          border: 3px solid #${colors.base0E};
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

      libinput = {
        enable = true;
        touchpad = {
          disableWhileTyping = true;
          naturalScrolling = true;
        };
      };

      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
          autoSuspend = true;
        };
      };
      desktopManager.gnome.enable = true;
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
      games.enable = false;
      tracker-miners.enable = false;
      tracker.enable = false;
    };

    environment.gnome.excludePackages = (with pkgs; [
      gnome-photos
      gnome-tour
      gedit # text editor
    ]) ++ (with pkgs.gnome; [
      cheese # webcam tool
      gnome-music
      epiphany # web browser
      geary # email reader
      gnome-characters
      tali # poker game
      iagno # go game
      hitori # sudoku game
      atomix # puzzle game
      yelp # Help view
      gnome-contacts
      gnome-initial-setup
    ]);
  };
}
