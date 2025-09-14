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

        #* Processes sorting, "pid" "program" "arguments" "threads" "user" "memory" "cpu lazy" "cpu direct",
        #* "cpu lazy" sorts top process over time (easier to follow), "cpu direct" updates top process directly.
        proc_sorting = "cpu direct";
        proc_gradient = false;
      };
    };
  };
}
