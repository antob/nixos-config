{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.hardware.ddcutil;
in
{
  options.antob.hardware.ddcutil = with types; {
    enable = mkEnableOption "Whether or not to enable ddcutil support";
  };

  config = mkIf cfg.enable {
    hardware.i2c.enable = true;
    antob.user.extraGroups = [ "i2c" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
    boot.kernelModules = [ "ddcci-backlight" ];
    environment.systemPackages = with pkgs; [
      ddcutil
    ];
  };
}
