{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.features.rpi;
in
{
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
                sha256 = "sha256:1algv6hb3sz02cy6y3hnxpa61qi3nanqg39gsgmjys62yc3xngj6";
                name = "catppuccin.tmTheme";
              };
            };
          };
        };
      };
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
      impala

      # raspberrypi-eeprom is used to update the pi firmware,
      # but since nixos has a different filesystem structure,
      # the firmware partition must be manually mounted first
      # sudo mount /dev/disk/by-label/FIRMWARE /mnt
      # sudo BOOTFS=/mnt rpi-eeprom-update -a
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

    # Bootloader.
    boot.loader.systemd-boot.enable = false;

    location = {
      latitude = mkDefault 57.7;
      longitude = mkDefault 11.8;
    };
  };
}
