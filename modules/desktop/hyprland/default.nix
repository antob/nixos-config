{ config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      imports = with nixos; [
        gtk
        nautilus
        noctalia
        rofi
      ];

      config = {
        antob = {
          rofi = {
            launchPrefix = "uwsm app -- ";
          };

          system.env = {
            # Hint electron apps to use wayland
            NIXOS_OZONE_WL = "1";
            QT_QPA_PLATFORMTHEME = "gtk3";
          };

          # nwg-displays config files
          persistence.home = {
            files = [
              ".config/hypr/monitors.lua"
              ".config/hypr/monitors.conf"
              ".config/hypr/workspaces.conf"
            ];
            directories = [
              ".config/nwg-displays"
            ];
          };
        };

        home-manager.sharedModules = [ homeManager.hyprland ];

        programs = {
          hyprland = {
            enable = true;
            withUWSM = true;
          };

          dconf.enable = true;
        };

        # xdg-desktop-portal-gnome FileChooser call depends on Nautilus
        services.dbus.packages = [ pkgs.nautilus ];

        # Desktop portal
        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
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

        environment.systemPackages = with pkgs; [
          gnome-calculator
          imv
          mpv
          sushi
          jq
          impala
          bluetui
          wiremix
          pamixer
          wl-clipboard
          nwg-displays
          libqalculate
          libnotify
        ];
        # Custom scripts
        # ++ (import ./scripts { inherit pkgs; });

        systemd.services."getty@tty1" = mkIf config.antob.user.autoLogin {
          overrideStrategy = "asDropin";
          serviceConfig.ExecStart = [
            ""
            "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${config.antob.user.name} --noclear --keep-baud %I 115200,38400,9600 $TERM"
          ];
        };

        environment.loginShellInit = ''
          if uwsm check may-start -q; then
            # Load Home Manager session vars before uwsm snapshots the environment;
            # login zsh only sources them from ~/.zprofile, which runs after this.
            hmVars="/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
            [ -r "$hmVars" ] && . "$hmVars"
            exec uwsm start hyprland-uwsm.desktop
          fi
        '';
      };
    };

  flake.modules.homeManager.hyprland =
    {
      config,
      osConfig,
      lib,
      ...
    }:
    with lib;
    let
      inherit (osConfig.stylix) cursor;
      inherit (osConfig.lib.stylix) colors;
    in
    {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          accent-color = "teal";
          gtk-theme = config.gtk.theme.name;
          cursor-theme = cursor.name;
          cursor-size = cursor.size;
        };
      };

      services.hyprpolkitagent.enable = true;

      # Border colours come from Stylix; keep the cyan accent on the active border.
      stylix.targets.hyprland = {
        enable = true;
        hyprpaper.enable = false;
      };

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        systemd.enable = false; # Conflicts with UWSM
        xwayland.enable = true; # Default
        settings.config.general."col.active_border" = mkForce "rgb(${colors.base0C})";
        # The Lua config is assembled from fragments (general.nix, rules.nix,
        # bindings.nix, bindings-layout.nix) ordered with mkOrder.
      };

      home.file.".config/uwsm/env".text = ''
        # Hint electron apps to use wayland
        export NIXOS_OZONE_WL=1;
        export QT_QPA_PLATFORMTHEME=gtk3

        # Cursor size
        export XCURSOR_SIZE=16
        export HYPRCURSOR_SIZE=16

        # Force all apps to use Wayland
        export GDK_BACKEND="wayland,x11,*"
        export QT_QPA_PLATFORM="wayland;xcb"
        export SDL_VIDEODRIVER=wayland
        export MOZ_ENABLE_WAYLAND=1
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        export OZONE_PLATFORM=wayland
      '';

      home.file.".config/uwsm/env-hyprland".text = ''
        # Cursor size
        export HYPRCURSOR_SIZE=16
      '';

      # Theme for hyprtoolkit apps, e.g. the xdph share picker.
      home.file.".config/hypr/hyprtoolkit.conf".text = ''
        background = rgba(${colors.base00}ff)
        base = rgba(${colors.base01}ff)
        alternate_base = rgba(${colors.base02}ff)
        text = rgba(${colors.base05}ff)
        bright_text = rgba(${colors.base00}ff)
        accent = rgba(${colors.base0D}ff)
        accent_secondary = rgba(${colors.base0C}ff)
      '';

      # xdg.portal = {
      #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # };
    };

}
