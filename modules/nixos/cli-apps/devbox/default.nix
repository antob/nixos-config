{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.cli-apps.devbox;
in {
  options.antob.cli-apps.devbox = with types; {
    enable = mkEnableOption "Whether or not to enable devbox.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ antob.devbox ];
    antob.persistence.home.directories = [ ".local/state/devbox" ];
  };
}
