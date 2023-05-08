{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.antob.desktop.gnome;
  gtkCfg = config.antob.desktop.addons.gtk;
in
{
  options.antob.desktop.gnome = with types; {
    enable = mkEnableOption "Enable Gnome Desktop.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnome.gnome-tweaks
    ];

    services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

    antob.system.env = {
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Desktop additions
    antob.desktop.addons.keyring = enabled;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

    # dconf and xfconf settings
    antob.home.extraOptions = {
      # xsession.enable = true;

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          enable-hot-corners = false;
          show-battery-percentage = true;
        };
        "org/gnome/desktop/wm/preferences" = {
          workspace-names = [ "Main" ];
          button-layout = ":minimize,maximize,close";
        };
        "org/gnome/settings-daemon/plugins/color" = {
          night-light-enabled = true;
        };
        "org/gnome/desktop/background" = {
          picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/pixels-l.webp";
          picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/pixels-d.webp";
          primary-color = "#967864";
        };
        "org/gnome/desktop/screensaver" = {
          picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/pixels-l.webp";
          primary-color = "#967864";
        };
        "org/gnome/desktop/peripherals/keyboard" = {
          delay = 200;
          repeat-interval = 40;
        };
        "system/locale" = {
          region = "sv_SE.UTF-8";
        };
        "org/gnome/nm-applet" = {
          disable-connected-notifications = true;
          disable-disconnected-notifications = true;
        };
      };
    };

    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Configure keymap in X11
      layout = "se,se";
      xkbVariant = "us,";
      xkbOptions = "caps:ctrl_modifier,grp:win_space_toggle";

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
        autoLogin = mkIf config.antob.user.autoLogin {
          enable = true;
          user = config.antob.user.name;
        };
        gdm.enable = true;
      };
      desktopManager.gnome.enable = true;
    };

    systemd.services = mkIf config.antob.user.autoLogin {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };

    services.gnome.games.enable = false;

    environment.gnome.excludePackages = (with pkgs; [
      gnome-photos
      gnome-tour
    ]) ++ (with pkgs.gnome; [
      cheese # webcam tool
      gnome-music
      gedit # text editor
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
