{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.easyeffects;
in
{
  options.antob.tools.easyeffects = with types; {
    enable = mkEnableOption "Enable EasyEffects";
    preset = mkOpt str null "Which preset to use when starting EasyEffects.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      services.easyeffects = {
        enable = true;
        preset = cfg.preset;
      };

      xdg.configFile."easyeffects/output/fw13.json".source = ./presets/fw13.json;
    };
  };
}
