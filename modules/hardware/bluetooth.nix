{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.bluetooth =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        home-manager.sharedModules = [ homeManager.bluetooth ];

        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              # ControllerMode = "bredr"; # Fix frequent Bluetooth audio dropouts
              Experimental = true;
              FastConnectable = true;
            };
            Policy = {
              AutoEnable = true;
            };
          };
        };

        services.blueman.enable = true;

        antob.persistence.directories = [ "/var/lib/bluetooth" ];
      };
    };

  flake.modules.homeManager.bluetooth =
    { lib, ... }:
    with lib;
    {
      dconf.settings = {
        "org/blueman/general" = {
          plugin-list = [ "!ConnectionNotifier" ];
        };
      };
    };

}
