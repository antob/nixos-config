{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];
      luks.devices."system".device = "/dev/disk/by-partlabel/cryptsystem";
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    kernelParams = [
      "nohibernate"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/system";
      fsType = "btrfs";
      options = [
        "subvol=@root"
        "compress=zstd"
      ];
    };

    "/home" = {
      device = "/dev/mapper/system";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
      ];
    };

    "/nix" = {
      device = "/dev/mapper/system";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
        "noatime"
      ];
    };

    "/swap" = {
      device = "/dev/mapper/system";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "compress=none"
        "noatime"
      ];
    };

    "/efi" = {
      device = "/dev/disk/by-partlabel/EFI";
      fsType = "vfat";
      options = [
        "dmask=0077"
        "fmask=0077"
      ];
      neededForBoot = true;
    };

    # ZFS
    "/mnt/tank" = {
      device = "zpool/tank";
      fsType = "zfs";
    };

    "/mnt/tank/temp" = {
      device = "zpool/temp";
      fsType = "zfs";
    };

    "/mnt/tank/archive" = {
      device = "zpool/archive";
      fsType = "zfs";
    };
  };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics.enable = true;

  # Derived from `head -c 8 /etc/machine-id`
  networking.hostId = "236689a3";
}
