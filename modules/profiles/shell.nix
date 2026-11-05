{ config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.shell =
    { lib, pkgs, ... }:
    {
      imports = with nixos; [
        base
        eza
        starship
        locale
        time
        openssh
        fzf
        zsh
        kitty
        git
        tmux
        neovim
      ];

      config = {
        home-manager.sharedModules = [ homeManager.shell ];

        antob.neovim.minimal = lib.mkDefault true;

        environment = {
          variables = {
            EDITOR = "nvim";
          };

          # Make hosts file writeable
          etc.hosts.mode = "0644";

          shellAliases = {
            sudo = "sudo "; # Fixes missing alias doing `sudo`
            cat = "bat -p";
            speedtest = "speedtest-rs";
          };

          systemPackages = with pkgs; [
            htop
            wget
            bottom
            ripgrep
            fd
            jq
            inetutils
            procs
            unzip
            dust
            killall
            duf
            usbutils
            pciutils
            e2fsprogs
            speedtest-rs
            file
            hostctl
            sops
            python3
          ];
        };

        location = {
          latitude = lib.mkDefault 57.7;
          longitude = lib.mkDefault 11.8;
        };
      };
    };

  flake.modules.homeManager.shell = {
    programs = {
      zoxide = {
        enable = true;
        options = [ "--cmd cd" ];
        enableZshIntegration = true;
      };

      bat.enable = true;
      btop.enable = true;
    };

    stylix.targets = {
      bat.enable = true;
      btop = {
        enable = true;
        opacity.enable = false;
      };
    };
  };
}
