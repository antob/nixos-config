{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.hyprsunset;
in
{
  options.antob.desktop.addons.hyprsunset = with types; {
    enable = mkEnableOption "Whether to enable Hyprsunset.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      services.hyprsunset = {
        enable = true;
        settings = {
          max-gamma = 150;

          profile = [
            {
              time = "7:00";
              temperature = 6000;
              gamma = 1.0;
            }
            {
              time = "20:00";
              temperature = 4000;
              gamma = 1.0;
            }
          ];
        };
      };
    };
  };
}
