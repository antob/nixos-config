# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd = {
      availableKernelModules =
        [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
      kernelModules = [ "kvm-intel" ];
      luks.devices."system".device = "/dev/disk/by-partlabel/cryptsystem";
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelParams = [
      "mem_sleep_default=deep"
      "resume_offset=140544" # Value from `btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile`
    ];
    resumeDevice = "/dev/mapper/system";
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=500M" "mode=755" ];
    };

    "/home/tob" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=1G" "mode=777" ];
    };

    "/nix" = {
      device = "/dev/mapper/system";
      fsType = "btrfs";
      # options = [ "subvol=@nix" "compress=zstd" "ssd" "noatime" ];
      options = [ "subvol=@nix" "compress=zstd" "noatime" ];
    };

    "/persist" = {
      device = "/dev/mapper/system";
      fsType = "btrfs";
      # options = [ "subvol=@persist" "compress=zstd" "ssd" "noatime" ];
      options = [ "subvol=@persist" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

    "/swap" = {
      device = "/dev/mapper/system";
      fsType = "btrfs";
      # options = [ "subvol=@swap" "compress=none" "ssd" "noatime" ];
      options = [ "subvol=@swap" "compress=none" "noatime" ];
    };

    "/efi" = {
      device = "/dev/disk/by-partlabel/EFI";
      fsType = "vfat";
      neededForBoot = true;
    };
  };

  swapDevices = [{ device = "/swap/swapfile"; }];

  # Enables DHCP on each ethernet and wireless interface.
  networking = {
    # Derived from `head -c 8 /etc/machine-id`
    hostId = "a789b055";

    useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp0s20f3.useDHCP = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  ## Other options to consider..
  # high-resolution display
  #hardware.video.hidpi.enable = true;
  #hardware.opengl.enable = true;
  #hardware.bluetooth.enable = true;
}
