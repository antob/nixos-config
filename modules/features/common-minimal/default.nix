{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.features.common-minimal;
in
{
  options.antob.features.common-minimal = with types; {
    enable = mkBoolOpt false "Whether or not to enable common minimal configuration.";
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
        neovim = enabled;
        tmux = enabled;
        yazi = enabled;
        sqlit = enabled;
      };

      hardware = {
        networking = enabled;
      };

      services = {
        openssh = enabled;
      };

      security.gpg = enabled;

      system = {
        locale = enabled;
        time = enabled;
        console = enabled;
      };

      persistence.enable = mkDefault false;

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
}
