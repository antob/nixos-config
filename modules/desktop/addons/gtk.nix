{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.gtk =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.gtk;
    in
    {
      options.antob.gtk = with types; {
        theme = {
          name = mkOpt str "Adwaita:dark" "The name of the GTK theme to apply.";
          pkg = mkOpt (nullOr package) null "The package to use for the theme.";
        };
        cursor = {
          name = mkOpt str "Bibata-Modern-Ice" "The name of the cursor theme to apply.";
          size = mkOpt int 16 "Cursor size to apply.";
          pkg = mkOpt (nullOr package) pkgs.bibata-cursors "The package to use for the cursor theme.";
        };
        icon = {
          name = mkOpt str "Adwaita" "The name of the icon theme to apply.";
          pkg = mkOpt package pkgs.adwaita-icon-theme "The package to use for the icon theme.";
        };
      };

      config = {
        home-manager.sharedModules = [ homeManager.gtk ];

        environment.systemPackages = [
          cfg.icon.pkg
          pkgs.adwaita-icon-theme-legacy
        ];

        environment.sessionVariables = {
          GTK_THEME = cfg.theme.name;
          XCURSOR_THEME = cfg.cursor.name;
          XCURSOR_SIZE = toString cfg.cursor.size;
        };

      };
    };

  flake.modules.homeManager.gtk =
    { osConfig, lib, ... }:
    with lib;
    let
      cfg = osConfig.antob.gtk;
    in
    {
      gtk = {
        enable = true;

        theme = {
          name = cfg.theme.name;
          package = cfg.theme.pkg;
        };

        cursorTheme = {
          name = cfg.cursor.name;
          size = cfg.cursor.size;
          package = cfg.cursor.pkg;
        };

        iconTheme = {
          name = cfg.icon.name;
          package = cfg.icon.pkg;
        };

        gtk3.extraConfig = {
          gtk-error-bell = false;
        };
        gtk4 = {
          theme = null; # See https://stopthemingmy.app
          extraConfig = {
            gtk-interface-color-scheme = "dark";
            gtk-error-bell = false;
          };
        };
      };
    };

}
