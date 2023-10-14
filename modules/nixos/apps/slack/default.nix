{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.apps.slack;
in {
  options.antob.apps.slack = with types; {
    enable = mkEnableOption "Enable Slack";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ slack ];
    antob.persistence.home.directories = [ ".config/Slack" ];
  };
}
