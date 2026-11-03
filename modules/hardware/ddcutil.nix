{
  flake.modules.nixos.ddcutil =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    {
      config = {
        hardware.i2c.enable = true;
        antob.user.extraGroups = [ "i2c" ];
        boot.extraModulePackages = [
          config.boot.kernelPackages.ddcci-driver
        ];
        boot.kernelModules = [ "ddcci-backlight" ];
        environment.systemPackages = [
          pkgs.ddcutil
        ];
      };
    };

}
