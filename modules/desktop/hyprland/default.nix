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
  lockScreen = config.antob.desktop.addons.hypridle.lockScreen;
  hypr-pkgs = inputs.hyprnix.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./addons/swayosd
  ];

  options.antob.desktop.hyprland = with types; {
    enable = mkEnableOption "Enable Hyprland.";
    enableCache = mkEnableOption "Enable Hyprland build cache.";
  };

  config = mkMerge [
    (mkIf cfg.enableCache {
      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };
    })
    (mkIf cfg.enable {
      programs = {
        hyprland = {
          enable = true;
          withUWSM = true;

          # set the flake package
          package = hypr-pkgs.hyprland;
          # make sure to also set the portal package, so that they are in sync
          portalPackage = hypr-pkgs.xdg-desktop-portal-hyprland;
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
            modulesLeft = [ "hyprland/workspaces" ];
            modulesRight = [
              "group/tray-expander"
              "bluetooth"
              "custom/external-ip"
              "network"
              "pulseaudio"
              "memory"
              "cpu"
              (mkIf config.antob.system.info.laptop "battery")
              "custom/networkd-vpn"
              "custom/hypridle"
              "custom/webcam"
              "clock"
            ];
          };
          hyprsunset = enabled;
          rofi = {
            enable = true;
            launchPrefix = "uwsm app -- ";
          };
          keyring = enabled;
          hyprlock.enable = lockScreen;
          hypridle = enabled;
          nautilus = enabled;
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
            package = hypr-pkgs.hyprland;
            # make sure to also set the portal package, so that they are in sync
            portalPackage = hypr-pkgs.xdg-desktop-portal-hyprland;

            systemd.enable = false; # Conflicts with UWSM
            xwayland.enable = true; # Default

            extraConfig = import ./config { inherit lib config pkgs; };
          };

          home.file.".config/uwsm/env".text = ''
            # Hint electron apps to use wayland
            export NIXOS_OZONE_WL=1;
            export QT_QPA_PLATFORMTHEME=qt6ct;

            # Cursor size
            export XCURSOR_SIZE=16
            export HYPRCURSOR_SIZE=16

            # Force all apps to use Wayland
            export GDK_BACKEND="wayland,x11,*"
            export QT_QPA_PLATFORM="wayland;xcb"
            export QT_STYLE_OVERRIDE=kvantum
            export SDL_VIDEODRIVER=wayland
            export MOZ_ENABLE_WAYLAND=1
            export ELECTRON_OZONE_PLATFORM_HINT=wayland
            export OZONE_PLATFORM=wayland
          '';

          home.file.".config/uwsm/env-hyprland".text = ''
            # Cursor size
            export HYPRCURSOR_SIZE=16
          '';

          xdg.portal = {
            extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          };
        };

        system.env = {
          # Hint electron apps to use wayland
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };
      };

      # Desktop portal
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
        };
      };

      environment.systemPackages =
        with pkgs;
        [
          gnome-calculator
          gnome-keyring
          gnome-themes-extra
          imv
          mpv
          sushi
          brightnessctl
          swayosd
          jq
          hyprshot
          hypr-pkgs.hyprpicker
          impala
          bluetui
          wiremix
          pamixer
          swaybg
          wl-clipboard
          wlr-dpms
          nwg-displays
          libqalculate
          gsettings-desktop-schemas
        ]
        # Custom scripts
        ++ (import ./scripts { inherit pkgs; });

      # nwg-displays config files
      antob.persistence.home.files = [
        ".config/hypr/monitors.conf"
        ".config/hypr/workspaces.conf"
      ];

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
    })
  ];
}
