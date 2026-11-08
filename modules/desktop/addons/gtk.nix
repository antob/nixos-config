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

        stylix.cursor = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 16;
        };

        environment.sessionVariables = {
          XCURSOR_THEME = config.stylix.cursor.name;
          XCURSOR_SIZE = toString config.stylix.cursor.size;
        };

      };
    };

  flake.modules.homeManager.gtk =
    { osConfig, lib, ... }:
    let
      cfg = osConfig.antob.gtk;
      inherit (osConfig.lib.stylix.colors) withHashtag;
    in
    {
      # Theme (adw-gtk3 + generated gtk.css) and cursor come from Stylix.
      stylix.targets.gtk = {
        enable = true;
        fonts.enable = false;
        flatpakSupport.enable = false;
        # Stylix uses base0D; match the cyan accent used elsewhere. The sidebar keeps the
        # flat look of unfocused windows by blending into the window background.
        extraCss = ''
          @define-color accent_color ${withHashtag.base0C};
          @define-color accent_bg_color ${withHashtag.base0C};
          @define-color sidebar_bg_color @window_bg_color;
        '';
      };

      gtk = {
        enable = true;

        iconTheme = {
          inherit (cfg.icon) name;
          package = cfg.icon.pkg;
        };

        gtk3.extraConfig = {
          gtk-error-bell = false;
        };
        gtk4.extraConfig = {
          gtk-interface-color-scheme = "dark";
          gtk-error-bell = false;
        };
      };
    };

}
