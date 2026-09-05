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
      cpuFreqGovernor = mkDefault "powersave";
      powertop.enable = true;
    };

    boot.extraModprobeConfig = ''
      options iwlwifi power_save=1
    '';

    services = {
      # Power optimizer daemons. Choose one.
      power-profiles-daemon.enable = true;
      tlp.enable = false;

      # Switch power-profiles-daemon profile when AC adapter changes state.
      udev.extraRules = ''
        ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
        ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
      '';

      logind.settings.Login = {
        HandleLidSwitch = mkDefault "suspend";
        HandleLidSwitchExternalPower = mkDefault "suspend";
      };
    };

    # Set the PPD profile at boot, once the daemon is available.
    systemd.services.ppd-ac-profile = {
      description = "Set power-profiles-daemon profile based on AC state";
      wantedBy = [ "power-profiles-daemon.service" ];
      after = [ "power-profiles-daemon.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ac_online=0
        for ps in /sys/class/power_supply/*; do
          [ "$(cat $ps/type)" = "Mains" ] && [ "$(cat $ps/online)" = "1" ] && ac_online=1
        done
        if [ "$ac_online" = "1" ]; then
          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced
        else
          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver
        fi
      '';
    };
  };
}
