{ config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.install-iso =
    {
      pkgs,
      lib,
      inputs,
      modulesPath,
      ...
    }:

    with lib;
    {
      antob.openssh = {
        permitRootLogin = true;
      };

      imports = with inputs; [
        (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
        nur.modules.nixos.default
        nixos.eza
        nixos.starship
        nixos.console
        nixos.fonts
        nixos.locale
        nixos.time
        nixos.audio
        nixos.bluetooth
        nixos.yubikey
        nixos.printing
        nixos.vscode
        nixos.firefox
        nixos.openssh
        nixos.fzf
        nixos.zsh
        nixos.alacritty
        nixos.gpg
        nixos.git
        nixos.tmux
        nixos.networking
        nixos.gnome
      ];

      # `install-iso` adds wireless support that
      # is incompatible with networkmanager.
      networking.wireless.enable = mkForce false;

      antob = {

        cli-apps = {
          neovim = enabled;
        };

        home.extraOptions.programs = {
          bat = {
            enable = true;
            config.theme = "catppuccin";
            themes = {
              catppuccin = {
                src = builtins.fetchurl {
                  url = "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme";
                  sha256 = "sha256:0xxashmrrj81y99ia4hvcpmplkzr1rlpgh4idf9inc7bikq6cm9r";
                  name = "catppuccin.tmTheme";
                };
              };
            };
          };
        };
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
        ungoogled-chromium
        gnome-calculator
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
        gparted
        nixos-anywhere
        disko
      ];

      system.stateVersion = "22.11";
    };
}
