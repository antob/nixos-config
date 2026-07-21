{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.features.laptop;
in
{
  options.antob.features.laptop = with types; {
    enable = mkBoolOpt false "Whether or not to enable laptop configuration.";
  };

  config = mkIf cfg.enable {
    antob = {
      features.desktop = enabled;
      system.info.laptop = true;
      hardware.fingerprint = enabled;
    };

    environment.systemPackages = with pkgs; [
      powertop
      iio-sensor-proxy # To enable automatic brightness in Gnome
    ];

    antob.persistence.directories = [
      "/var/lib/powertop"
    ];

    powerManagement = {
      cpuFreqGovernor = lib.mkDefault "powersave";
      powertop.enable = true;
    };

    services = {
      # Power optimizer daemons. Choose one.
      power-profiles-daemon.enable = true;
      tlp.enable = false;

      logind.settings.Login = {
        HandleLidSwitch = "suspend-then-hibernate";
        HandleLidSwitchExternalPower = "suspend";
      };
    };
  };
}
