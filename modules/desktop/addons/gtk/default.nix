{ options, config, lib, pkgs, ... }:

with lib;
let cfg = config.antob.desktop.addons.gtk;
in {
  options.antob.desktop.addons.gtk = with types; {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
    theme = {
      name = mkOpt str "Adwaita-dark" "The name of the GTK theme to apply.";
      pkg = mkOpt (nullOr package) "The package to use for the theme.";
    };
    cursor = {
      name =
        mkOpt str "Bibata-Modern-Ice" "The name of the cursor theme to apply.";
      pkg = mkOpt package pkgs.bibata-cursors
        "The package to use for the cursor theme.";
    };
    icon = {
      name = mkOpt str "Papirus" "The name of the icon theme to apply.";
      pkg = mkOpt package pkgs.papirus-icon-theme
        "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.icon.pkg cfg.cursor.pkg ];

    environment.sessionVariables = {
      GTK_THEME = gtk.theme.name;
      XCURSOR_THEME = cfg.cursor.name;
    };

    antob.home.extraOptions = {
      gtk = {
        enable = true;

        theme = {
          name = cfg.theme.name;
          package = optional (cfg.theme.pkg != null) cfg.theme.pkg;
        };

        cursorTheme = {
          name = cfg.cursor.name;
          package = cfg.cursor.pkg;
        };

        iconTheme = {
          name = cfg.icon.name;
          package = cfg.icon.pkg;
        };

        gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };
        gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
      };
    };
  };
}
