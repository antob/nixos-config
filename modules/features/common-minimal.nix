{ config, ... }:
let
  inherit (config.flake.lib) enabled;
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.common-minimal =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      imports = [
        nixos.env
        nixos.eza
        nixos.starship
        nixos.console
        nixos.locale
        nixos.time
        nixos.yazi
        nixos.openssh
        nixos.fzf
        nixos.zsh
        nixos.kitty
        nixos.gpg
        nixos.git
        nixos.tmux
        nixos.neovim
      ];

      config = {
        home-manager.sharedModules = [ homeManager.common-minimal ];

        antob.neovim = {
          minimal = true;
        };

        antob = {

          # sqlit = enabled;

        };

        environment.variables = {
          EDITOR = "nvim";
        };

        # Make hosts file writeable
        environment.etc.hosts.mode = "0644";

        environment.shellAliases = {
          sudo = "sudo "; # Fixes missing alias doing `sudo`
          cat = "bat -p";
          speedtest = "speedtest-rs";
        };

        environment.systemPackages = with pkgs; [
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
          dmidecode
          usbutils
          pciutils
          gnumake
          e2fsprogs
          speedtest-rs
          file
          nvd
          hostctl
          sops
          witr
          python3
          bun
          nmap
          arp-scan
        ];

        services = {
          upower.enable = true;
          dbus.enable = true;
        };

        # Bootloader.
        boot.loader = {
          systemd-boot = {
            enable = mkDefault true;
            consoleMode = "max";
            configurationLimit = 10;
            editor = false;
          };

          efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/efi";
          };
        };

        location = {
          latitude = mkDefault 57.7;
          longitude = mkDefault 11.8;
        };
      };
    };

  flake.modules.homeManager.common-minimal =
    { lib, ... }:
    with lib;
    {
      programs = {
        zoxide = {
          enable = true;
          options = [ "--cmd cd" ];
          enableZshIntegration = true;
        };

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

}
