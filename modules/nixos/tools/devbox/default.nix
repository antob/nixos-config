{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.devbox;
in
{
  options.antob.tools.devbox = with types; {
    enable = mkEnableOption "Whether or not to enable devbox.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ devbox ];
    antob.persistence.home.directories = [ ".local/state/devbox" ];
  };
}
