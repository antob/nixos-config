{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.addons.gtk;
in
{
  options.antob.desktop.addons.gtk = with types; {
    enable = mkEnableOption "Whether to customize GTK and apply themes.";
    theme = {
      name = mkOpt str "Adwaita-dark" "The name of the GTK theme to apply.";
      pkg = mkOpt (nullOr package) null "The package to use for the theme.";
    };
    cursor = {
      name = mkOpt str "Bibata-Modern-Ice" "The name of the cursor theme to apply.";
      size = mkOpt int 16 "Cursor size to apply.";
      pkg = mkOpt (nullOr package) pkgs.bibata-cursors "The package to use for the cursor theme.";
    };
    icon = {
      name = mkOpt str "Papirus" "The name of the icon theme to apply.";
      pkg = mkOpt package pkgs.papirus-icon-theme "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.icon.pkg ];

    environment.sessionVariables = {
      GTK_THEME = cfg.theme.name;
      XCURSOR_THEME = cfg.cursor.name;
      XCURSOR_SIZE = builtins.toString cfg.cursor.size;
    };

    antob.home.extraOptions = {
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
          gtk-application-prefer-dark-theme = 1;
          gtk-error-bell = false;
        };
        gtk4.extraConfig = {
          gtk-error-bell = false;
        };
      };
    };
  };
}
