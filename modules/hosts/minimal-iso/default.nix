{ config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.minimal-iso =
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
        nixos.eza
        nixos.starship
        nixos.console
        nixos.fonts
        nixos.locale
        nixos.time
        nixos.bluetooth
        nixos.yubikey
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
          fzf = enabled;
        };

        cli-apps = {
          neovim = enabled;
          tmux = enabled;
        };

        hardware = {
          networking = enabled;
        };

        services.openssh = {
          enable = true;
          permitRootLogin = true;
        };

        security.gpg = enabled;

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
        killall
        doggo
        dmidecode
        usbutils
        pciutils
        gnumake
        cifs-utils # Mount SMB shares
        file
        btrfs-progs
        parted
        nixos-anywhere
        disko
      ];

      system.stateVersion = "22.11";
    };
}
