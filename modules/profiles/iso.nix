{ config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.iso =
    { lib, pkgs, ... }:
    {
      imports = with nixos; [
        base
        env
        eza
        starship
        console
        fonts
        locale
        time
        bluetooth
        yubikey
        openssh
        fzf
        zsh
        alacritty
        gpg
        git
        tmux
        networking
        neovim
      ];

      antob.openssh = {
        permitRootLogin = true;
      };

      # `install-iso` adds wireless support that
      # is incompatible with networkmanager.
      networking.wireless.enable = lib.mkForce false;

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
          nixos-anywhere
          disko
        ];
      };

      system.stateVersion = "22.11";
    };
}
