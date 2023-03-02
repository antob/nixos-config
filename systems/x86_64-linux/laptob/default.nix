{ pkgs, config, lib, channel, ... }:

with lib;
{
  imports = [ ./hardware.nix ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Bootloader.
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };

    initrd = {
      # Setup keyfile
      secrets = {
        "/crypto_keyfile.bin" = null;
      };

      # Enable swap on luks
      luks.devices.swap = {
        device = "/dev/disk/by-label/crypt-swap";
        keyFile = "/crypto_keyfile.bin";
      };
    };
  };

  antob = {
    user = {
      name = "tob";
      fullName = "Tobias Lindholm";
      email = "tobias.lindholm@antob.se";
      initialPassword = "password";
    };

    services = {
      openssh = enabled;
      avahi = enabled;
      printing = enabled;
    };

    hardware = {
      fingerprint = enabled;
      networking = enabled;
    };

    system = {
      time = enabled;
      locale = enabled;
      console = enabled;
    };

    tools = {
      git = enabled;
      neovim = enabled;
    };
  };

  environment.systemPackages = with pkgs; [
    firefox
  ];

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "22.11";
}
