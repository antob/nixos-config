{ inputs, ... }:
let
  inherit (inputs) nixos-raspberrypi;
in
{
  flake.modules.nixos.pikvm =
    { lib, ... }:

    with lib;
    {
      imports = with inputs; [
        nixos-raspberrypi.nixosModules.sd-image
        kvmd.nixosModules.default
        kvmd.nixosModules.v2-hdmi-rpi4
      ];

      sdImage.compressImage = false;
    };
}
