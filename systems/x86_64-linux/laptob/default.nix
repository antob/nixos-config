{ pkgs, config, lib, channel, inputs, ... }:

with lib; {
  imports = [ ./hardware.nix ];

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      configurationLimit = 5;
      # https://github.com/NixOS/nixpkgs/blob/c32c39d6f3b1fe6514598fa40ad2cf9ce22c3fb7/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix#L66
      editor = false;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
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
      hashedPassword =
        "$y$j9T$wjUKjUTgvrxCg7HVJIrl2/$A0nvjyLzv869pQYmjyuIgXafrZDk2Lzg9B/nA/W4609";
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
      audio = enabled;
    };

    system = {
      time = enabled;
      locale = enabled;
      console = enabled;
      fonts = enabled;
    };

    persistence = {
      enable = true;

      directories = [ "/etc/NetworkManager/system-connections" ];
      files = [
        "/etc/machine-id"
        "/ssh/ssh_host_rsa_key"
        "/ssh/ssh_host_rsa_key.pub"
        "/ssh/ssh_host_ed25519_key"
        "/ssh/ssh_host_ed25519_key.pub"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    htop
    wget
    gcc
    inetutils
    gnumake
    powertop
    procs
    unzip
    du-dust
  ];

  system.stateVersion = "22.11";
}
