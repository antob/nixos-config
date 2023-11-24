{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.services.gammastep;
in {
  options.antob.services.gammastep = with types; {
    enable = mkEnableOption "Whether or not to enable Redshift.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = config.location.latitude;
      longitude = config.location.longitude;
    };
  };
}
