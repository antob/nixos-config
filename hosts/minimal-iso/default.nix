{
  pkgs,
  lib,
  modulesPath,
  ...
}:

with lib;
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
    ../../modules
  ];

  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  # Enable dconf to manage settings
  programs.dconf.enable = true;

  antob = {
    tools = {
      alacritty = enabled;
      git = enabled;
      zsh = enabled;
      starship = enabled;
      eza = enabled;
      fzf = enabled;
    };

    cli-apps = {
      neovim = enabled;
      tmux = enabled;
    };

    hardware = {
      bluetooth = enabled;
      yubikey = enabled;
      networking = enabled;
    };

    services.openssh = {
      enable = true;
      permitRootLogin = true;
    };

    security.gpg = enabled;

    system = {
      fonts = enabled;
      locale = enabled;
      time = enabled;
      console = enabled;
    };

    virtualisation.docker.enable = false;
    virtualisation.podman.enable = false;
  };

  services = {
    upower.enable = true;
    dbus.enable = true;
  };

  location = {
    latitude = 57.7;
    longitude = 11.8;
  };

  environment.variables = {
    EDITOR = "nvim";
  };

  environment.shellAliases = {
    sudo = "sudo "; # Fixes missing alias doing `sudo`
    cat = "bat -p";
  };

  environment.systemPackages = with pkgs; [
    htop
    wget
    bottom
    ripgrep
    fd
    inetutils
    procs
    unzip
    fwupd
    killall
    dogdns
    dmidecode
    usbutils
    pciutils
    gnumake
    cifs-utils # Mount SMB shares
    file
    btrfs-progs
    parted
  ];

  system.stateVersion = "22.11";
}
