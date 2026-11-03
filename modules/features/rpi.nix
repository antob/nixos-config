{ inputs, config, ... }:
let
  inherit (config.flake.lib) enabled;
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.rpi =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      imports = [

        # transitive deps
        nixos.eza
        nixos.starship
        nixos.locale
        nixos.time
        nixos.openssh
        nixos.fzf
        nixos.zsh
        nixos.kitty
        nixos.git
        nixos.tmux
        nixos.neovim
      ];

      config = {
        home-manager.sharedModules = [ homeManager.rpi ];

        antob.neovim = {
          minimal = true;
        };

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
        };

        environment.systemPackages = with pkgs; [
          htop
          wget
          bottom
          ripgrep
          fd
          jq
          inetutils
          impala
          libraspberrypi
          raspberrypi-eeprom
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

        nix.settings.filter-syscalls = false;
        documentation.enable = lib.mkDefault false;

        location = {
          latitude = mkDefault 57.7;
          longitude = mkDefault 11.8;
        };

        # Bootloader.
        boot = {
          loader.systemd-boot.enable = false;
          zfs.forceImportRoot = false;
          supportedFilesystems.zfs = false;
        };
      };
    };

  flake.modules.homeManager.rpi =
    { lib, ... }:
    with lib;
    {
      config = lib.mkMerge [
        ({
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
        })
        ({ home.enableNixpkgsReleaseCheck = false; })
      ];
    };

}
