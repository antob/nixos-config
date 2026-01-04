{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.sqlit;
in
{
  options.antob.cli-apps.sqlit = with types; {
    enable = mkEnableOption "Whether or not to enable sqlit.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sqlit-tui
    ];

    environment.variables = {
      SQLIT_CONFIG_DIR = "./config/sqlit";
    };

    antob.persistence = {
      home.directories = [ ".config/sqlit" ];
    };
  };
}
