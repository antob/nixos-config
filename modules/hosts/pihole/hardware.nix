{ inputs, ... }:
let
  inherit (inputs) nixos-raspberrypi;
in
{
  flake.modules.nixos.pihole =
    { lib, config, ... }:

    with lib;
    {
      imports = with nixos-raspberrypi.nixosModules; [
        sd-image
        raspberry-pi-4.base
      ];

      sdImage.compressImage = false;
    };
}
