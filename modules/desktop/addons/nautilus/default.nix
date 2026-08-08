{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.nautilus;
in
{
  options.antob.desktop.addons.nautilus = with types; {
    enable = mkEnableOption "Whether to enable Nautilus.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nautilus
    ];

    services.gnome.sushi.enable = false;

    antob.persistence.home.directories = [
      ".local/share/nautilus"
      ".config/gtk-3.0" # Bookmarks
      ".config/dconf" # Settings
    ];
  };
}
