{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.services.redshift;
in {
  options.antob.services.redshift = with types; {
    enable = mkEnableOption "Whether or not to enable Redshift.";
  };

  config = mkIf cfg.enable {
    services.redshift.enable = true;
  };
}
