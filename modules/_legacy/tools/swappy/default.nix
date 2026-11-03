{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.swappy;
in
{
  options.antob.tools.swappy = with types; {
    enable = mkEnableOption "Whether or not to enable swappy.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.swappy = {
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
