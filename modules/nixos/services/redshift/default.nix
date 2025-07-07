{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.services.redshift;
  lcfg = config.location;
in
{
  options.antob.services.redshift = with types; {
    enable = mkEnableOption "Whether or not to enable Redshift.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.services.redshift = {
      enable = true;
      provider = "manual";
      latitude = lcfg.latitude;
      longitude = lcfg.longitude;
    };

  };
}
