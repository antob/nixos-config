{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.btop;
in
{
  options.antob.tools.btop = with types; {
    enable = mkEnableOption "Whether or not to enable btop.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.btop = {
      enable = true;
      settings = {
        color_theme = "${pkgs.btop}/share/btop/themes/tokyo-storm.theme";

        #* Define presets for the layout of the boxes. Preset 0 is always all boxes shown with default settings. Max 9 presets.
        #* Format: "box_name:P:G,box_name:P:G" P=(0 or 1) for alternate positions, G=graph symbol to use for box.
        #* Use whitespace " " as separator between different presets.
        #* Example: "cpu:0:default,mem:0:tty,proc:1:default cpu:0:braille,proc:0:tty"
        presets = "cpu:0:default,proc:1:default";
      };
    };
  };
}
