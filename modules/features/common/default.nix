{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
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
        scripts = enabled;
      };

      cli-apps = {
        neovim = enabled;
        helix = enabled;
        tmux = enabled;
        yazi = enabled;
        nix-search-tv = enabled;
        sqlit = enabled;
        opencode = enabled;
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

    environment.variables = {
      EDITOR = "nvim";
    };

    # Make hosts file writeable
    environment.etc.hosts.mode = "0644";

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
      dust
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
      hostctl
      nix-search-tv
      just
      nixos-anywhere
      sops
      man-pages
      man-pages-posix
      witr
      wl-color-picker
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

    documentation = {
      enable = true;
      man.enable = true;
      man.man-db.enable = true;
      dev.enable = true;
    };
  };
}
