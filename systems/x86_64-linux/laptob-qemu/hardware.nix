{ config, lib, pkgs, modulesPath, inputs, ... }:

let inherit (inputs) nixos-hardware;
in {
  imports = with nixos-hardware.nixosModules;
    [
      (modulesPath + "/profiles/qemu-guest.nix")
      ./disk-config.nix
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules =
        [ "ahci" "xhci_pci" "virtio_pci" "sd_mod" "virtio_blk" ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Enable DHCP on the wireless link
  networking = {
    useDHCP = lib.mkDefault true;
  };
}
