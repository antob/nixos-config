{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.addons.udisks2;
in
{
  options.antob.desktop.addons.udisks2 = with types; {
    enable = mkEnableOption "Whether to enable udisks2.";
  };

  config = mkIf cfg.enable { services.udisks2.enable = true; };
}
