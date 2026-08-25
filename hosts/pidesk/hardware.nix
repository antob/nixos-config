{
  lib,
  inputs,
  modulesPath,
  ...
}:

with lib;
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    inputs.nixos-hardware-pi.nixosModules.raspberry-pi-4
  ];

  sdImage.compressImage = false;

  boot = {
    initrd.allowMissingModules = true;
    supportedFilesystems = mkForce [
      "vfat"
      "ext4"
    ];
  };

  hardware.raspberry-pi.firmware.uboot.enable = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "aarch64-linux";
}
