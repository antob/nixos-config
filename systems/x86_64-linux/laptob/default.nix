{ pkgs, config, lib, channel, inputs, ... }:

with lib;
{
  imports = [
    ./hardware.nix
    inputs.impermanence.nixosModules.impermanence
    ./persist.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Bootloader.
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        configurationLimit = 5;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
    };
  };

  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    lidSwitchExternalPower = "suspend";
  };

  antob = {
    user = {
      name = "tob";
      fullName = "Tobias Lindholm";
      email = "tobias.lindholm@antob.se";
      initialPassword = "password";
      autoLogin = true;
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
  ];

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "22.11";
}
