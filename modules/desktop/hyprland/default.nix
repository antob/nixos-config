{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.hyprland;
  gtkCfg = config.antob.desktop.addons.gtk;
in
{
  imports = [
    ./addons/swayosd
  ];

  options.antob.desktop.hyprland = with types; {
    enable = mkEnableOption "Enable Hyprland.";
  };

  config = mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;

        # set the flake package
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };

      dconf.enable = true;
    };

    antob = {
      desktop.addons = {
        gtk = enabled;
        mako = enabled;
        waybar = {
          enable = true;
          enableSystemd = true;
        };
        hyprsunset = enabled;
        walker = enabled;
        keyring = enabled;
        hyprlock = enabled;
        hypridle = enabled;
      };

      tools.btop = enabled;

      home.extraOptions = {
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = gtkCfg.theme.name;
            cursor-theme = gtkCfg.cursor.name;
            cursor-size = gtkCfg.cursor.size;
          };
        };

        services.hyprpolkitagent.enable = true;

        wayland.windowManager.hyprland = {
          enable = true;

          # set the flake package
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          portalPackage =
            inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

          systemd.enable = false; # Conflicts with UWSM
          xwayland.enable = true; # Default

          plugins = [
            inputs.hyprland-plugins.packages.${pkgs.system}.hyprscrolling
          ];
          extraConfig = import ./config { inherit lib config pkgs; };
        };

        # Default apps
        xdg.mimeApps.defaultApplications = {
          "image/png" = [ "org.gnome.Loupe.desktop" ];
          "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
          "application/pdf" = [ "org.gnome.Evince.desktop" ];
        };
      };

      system.env = {
        # Hint electron apps to use wayland
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };
    };

    nix.settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };

    # Needed for Impala (network management TUI)
    networking.wireless.iwd.enable = true;

    # Desktop portal
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    environment.systemPackages =
      with pkgs;
      [
        gnome-calculator
        gnome-keyring
        gnome-themes-extra
        nautilus
        sushi
        loupe
        evince
        brightnessctl
        swayosd
        jq
        hyprshot
        hyprpicker
        impala
        bluetui
        blueberry
        wiremix
        pamixer
        swaybg
        wl-clipboard
        nwg-displays
        libqalculate

        # Custom scripts
        # hyprland-protocols
        # xorg.xlsclients
      ]
      # Custom scripts
      ++ (import ./scripts { inherit pkgs; });

    # nwg-displays config files
    antob.persistence.home.files = [
      ".config/hypr/monitors.conf"
      ".config/hypr/workspaces.conf"
    ];

    services.gnome.at-spi2-core.enable = true;

    systemd.services."getty@tty1" = mkIf config.antob.user.autoLogin {
      overrideStrategy = "asDropin";
      serviceConfig.ExecStart = [
        ""
        "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${config.antob.user.name} --noclear --keep-baud %I 115200,38400,9600 $TERM"
      ];
    };

    environment.loginShellInit = ''
      if uwsm check may-start -q; then
        exec uwsm start hyprland-uwsm.desktop
      fi
    '';
  };
}
