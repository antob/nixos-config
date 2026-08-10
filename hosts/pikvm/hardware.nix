{
  lib,
  modulesPath,
  ...
}:

with lib;
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  sdImage.compressImage = false;

  boot.supportedFilesystems = mkForce [
    "vfat"
    "ext4"
  ];

  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "aarch64-linux";
}
