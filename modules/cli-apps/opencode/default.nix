{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.opencode;
in
{
  options.antob.cli-apps.opencode = with types; {
    enable = mkEnableOption "Whether or not to enable opencode.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      opencode
    ];

    antob.persistence = {
      home.directories = [ ".config/opencode" ];
    };
  };
}
