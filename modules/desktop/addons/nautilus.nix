{
  flake.modules.nixos.nautilus =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      config = {
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
    };

}
