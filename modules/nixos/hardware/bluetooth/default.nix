{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;
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
      settings.General.Experimental = "true";
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
