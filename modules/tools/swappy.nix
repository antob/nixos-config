{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.swappy =
    { lib, ... }:

    {
      home-manager.sharedModules = [ homeManager.swappy ];

    };

  flake.modules.homeManager.swappy =
    { lib, ... }:
    {
      programs.swappy = {
        enable = true;
        settings = {
          Default = {
            auto_save = false;
            early_exit = true;
            fill_shape = false;
            line_size = 3;
            paint_mode = "rectangle";
            save_dir = "$HOME/Pictures/Screenshots";
            save_filename_format = "screenshot-%Y%m%d-%H%M%S.png";
            show_panel = false;
            text_font = "sans-serif";
            text_size = 20;
            transparency = 50;
            transparent = false;
          };
        };
      };
    };

}
