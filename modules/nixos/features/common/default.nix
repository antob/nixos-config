{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.features.common;
in
{
  options.antob.features.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    antob = {
      tools = {
        alacritty = enabled;
        git = enabled;
        zsh = enabled;
        starship = enabled;
        eza = enabled;
        direnv = enabled;
        devenv = enabled;
        rustup = enabled;
        fzf = enabled;
      };

      cli-apps = {
        neovim = enabled;
        helix = enabled;
        tmux = enabled;
      };

      # virtualisation.podman = enable = mkDefault true;
      virtualisation.docker.enable = mkDefault true;

      hardware = {
        networking = enabled;
        audio = enabled;
      };

      services = {
        openssh = enabled;
      };

      security.gpg = enabled;

      system = {
        fonts = enabled;
        locale = enabled;
        time = enabled;
        console = enabled;
      };

      persistence.enable = false;
      persistence = {
        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/lib/systemd/backlight"
        ];
        files = [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
        ];
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

        password-store.enable = true;

        # DNS lookup failure on update during boot
        # tealdeer.enable = true;
      };
    };

    nix.settings = {
      experimental-features = "nix-command flakes";
      http-connections = 50;
      warn-dirty = false;
      log-lines = 50;
      sandbox = "relaxed";
      auto-optimise-store = true;
      trusted-users = [
        "root"
        config.antob.user.name
      ];
      allowed-users = [
        "root"
        config.antob.user.name
      ];
      substituters = [
        "https://cache.nixos.org/"
        "https://cosmic.cachix.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];
    };

    environment.variables = {
      EDITOR = "nvim";
    };

    environment.shellAliases = {
      sudo = "sudo "; # Fixes missing alias doing `sudo`
      cat = "bat -p";
      http = "xh";
      https = "xhs";
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
      du-dust
      fwupd
      killall
      dogdns
      duf
      jqp
      xh
      neofetch
      dmidecode
      usbutils
      pciutils
      gnumake
      cifs-utils # Mount SMB shares
      speedtest-rs
      file
      nvd
    ];

    services = {
      upower.enable = true;
      dbus.enable = true;
      # Disable for now to avoid failed systemd
      # units (`bin.mount` and `usr-bin.mount`) on startup
      # envfs.enable = true;
    };

    location = {
      latitude = 57.7;
      longitude = 11.8;
    };

    # Bootloader.
    boot.loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        configurationLimit = 5;
        # https://github.com/NixOS/nixpkgs/blob/c32c39d6f3b1fe6514598fa40ad2cf9ce22c3fb7/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix#L66
        editor = false;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
    };

    systemd.tmpfiles.rules = lib.mkIf (config.antob.persistence.enable) [
      "d /persist/var/log 0755 root root -"
      "d /persist/var/lib/nixos 0755 root root -"
      "d /persist/var/lib/systemd/coredump 0755 root root -"
      "d /mnt 0755 root root -"
    ];
  };
}
