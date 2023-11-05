{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.hardware.zsa-voyager;
in
{
  options.antob.hardware.zsa-voyager = with types; {
    enable = mkBoolOpt false "Whether or not to enable zsa-voyager support.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ wally-cli ];
    antob.user.extraGroups = [ "plugdev" ];

    services.udev.extraRules = ''
      # Rules for Oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"
      # Keymapp Flashing rules for the Voyager
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
    '';
  };
}
