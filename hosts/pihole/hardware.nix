{
  lib,
  config,
  nixos-raspberrypi,
  ...
}:

with lib;
{
  imports = with nixos-raspberrypi.nixosModules; [
    sd-image
    raspberry-pi-4.base
  ];

  sdImage.compressImage = false;
}
