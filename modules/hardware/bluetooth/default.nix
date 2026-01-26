{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.hardware.bluetooth;
in
{
  options.antob.hardware.bluetooth = with types; {
    enable = mkBoolOpt false "Whether or not to enable bluetooth support.";
  };

  config = mkIf cfg.enable {
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

    antob.home.extraOptions.dconf.settings = {
      "org/blueman/general" = {
        plugin-list = [ "!ConnectionNotifier" ];
      };
    };

    antob.persistence.directories = [ "/var/lib/bluetooth" ];
  };
}
