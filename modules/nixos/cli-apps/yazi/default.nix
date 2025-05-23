{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.cli-apps.yazi;
in
{
  options.antob.cli-apps.yazi = with types; {
    enable = mkEnableOption "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;

        settings = {
          log = {
            enabled = false;
          };
          manager = {
            show_hidden = true;
            sort_dir_first = true;
            scrolloff = 3;
          };
        };
      };
    };
  };
}
