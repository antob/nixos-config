{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.features.rpi;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko

    ../../user
    ../../home
    ../../nix
    ../../persistence
    ../../color-scheme

    ../../tools/kitty
    ../../tools/git
    ../../tools/zsh
    ../../tools/starship
    ../../tools/eza
    ../../tools/fzf
    ../../cli-apps/neovim
    ../../cli-apps/tmux
    ../../services/openssh
    ../../system/locale
    ../../system/time

    ../../hardware/systemd-networking
    ../../services/wireguard

    # transitive deps
    ../../security/gpg
    ../../hardware/networking
    ../../services/avahi
    ../../services/networkd-vpn
  ];

  options.antob.features.rpi = with types; {
    enable = mkBoolOpt false "Whether or not to enable Raspberry Pi configuration.";
  };

  config = mkIf cfg.enable {
    antob = {
      tools = {
        kitty = enabled;
        git = enabled;
        zsh = enabled;
        starship = enabled;
        eza = enabled;
        fzf = enabled;
      };

      cli-apps = {
        neovim = {
          enable = true;
          minimal = true;
        };
        tmux = enabled;
      };

      services.openssh = enabled;

      system = {
        locale = enabled;
        time = enabled;
      };

      home.extraOptions.programs = {
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

      home.extraOptions.home.enableNixpkgsReleaseCheck = false;
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
}
