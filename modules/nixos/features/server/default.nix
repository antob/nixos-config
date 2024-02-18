{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.features.server;
in
{
  options.antob.features.server = with types; {
    enable = mkBoolOpt false "Whether or not to enable server configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
    ];
  };
}
