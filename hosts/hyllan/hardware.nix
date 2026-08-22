{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
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
    };

    kernelModules = [
      "kvm-amd"
      "ext4"
      "vfat"
    ];
    extraModulePackages = [ ];
    kernelParams = [
      "nohibernate"
    ];

    # Enable emulated systems for cross-compilation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  fileSystems = {
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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics.enable = true;
}
