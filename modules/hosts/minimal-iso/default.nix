{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
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
      antob.openssh = {
        permitRootLogin = true;
      };

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
        nixos.openssh
        nixos.fzf
        nixos.zsh
        nixos.alacritty
        nixos.gpg
        nixos.git
        nixos.tmux
        nixos.networking
        nixos.neovim
        nixos.base
        nixos.env
      ];

      # `install-iso` adds wireless support that
      # is incompatible with networkmanager.
      networking.wireless.enable = mkForce false;

      # Enable dconf to manage settings
      programs.dconf.enable = true;

      services = {
        upower.enable = true;
        dbus.enable = true;
      };

      location = {
        latitude = 57.7;
        longitude = 11.8;
      };

      environment = {
        variables = {
          EDITOR = "nvim";
        };

        shellAliases = {
          sudo = "sudo "; # Fixes missing alias doing `sudo`
          cat = "bat -p";
        };

        systemPackages = with pkgs; [
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
      };

      system.stateVersion = "22.11";
    };

  flake.nixosConfigurations.minimal-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ nixos.minimal-iso ];
  };
}
