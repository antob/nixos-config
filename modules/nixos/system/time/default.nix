{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.system.time;
in
{
  options.antob.system.time = with types; {
    enable = mkEnableOption "Whether or not to configure timezone information.";
  };

  config = mkIf cfg.enable { time.timeZone = "Europe/Stockholm"; };
}
