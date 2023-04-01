{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.hardware.bluetooth;
in {
  options.antob.hardware.bluetooth = with types; {
    enable = mkBoolOpt false "Whether or not to enable bluetooth support.";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    antob.persistence.directories = [ "/var/lib/bluetooth" ];
  };
}
