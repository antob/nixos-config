{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;

let
  cfg = config.antob.services.gammastep;
  lcfg = config.location;
in
{
  options.antob.services.gammastep = with types; {
    enable = mkEnableOption "Whether or not to enable Gammastep.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = lcfg.latitude;
      longitude = lcfg.longitude;
    };
  };
}
