{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
      kernelModules = [ "kvm-intel" ];
      luks.devices.root.device = "/dev/disk/by-label/crypt-nixos";
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelParams = [ "mem_sleep_default=deep" "resume_offset=140544" ];
    resumeDevice = "/dev/disk/by-uuid/54482a88-e7a0-4942-a5ea-03581cec2767";
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "ext4";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
  };

  swapDevices = [{ device = "/dev/mapper/swap"; }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  #powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  #hardware.cpu.intel.updateMicrocode =
  #  lib.mkDefault config.hardware.enableRedistributableFirmware;

  # high-resolution display
  #hardware.video.hidpi.enable = true;

  #hardware.opengl.enable = true;

  #hardware.bluetooth.enable = true;

  # Enable DHCP on the wireless link
  networking = {
    # Derived from `head -c 8 /etc/machine-id`
    hostId = "a789b055";

    useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp0s20f3.useDHCP = true;
  };
}
