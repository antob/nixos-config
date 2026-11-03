{ config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.common =
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
        nixos.direnv
        nixos.devenv
        nixos.rustup
        nixos.fhs
        nixos.console
        nixos.fonts
        nixos.locale
        nixos.time
        nixos.audio
        nixos.yazi
        nixos.openssh
        nixos.scripts
        nixos.fzf
        nixos.zsh
        nixos.kitty
        nixos.alacritty
        nixos.gpg
        nixos.git
        nixos.tmux
        nixos.nix-search-tv
        nixos.neovim
      ];

      config = {
        home-manager.sharedModules = [ homeManager.common ];

        antob = {

          # sqlit = enabled;

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
            http = "xh";
            https = "xhs";
            speedtest = "speedtest-rs";
            j = "just";
            open = "xdg-open";
            hexyl = "hexyl --border none --color-scheme gradient";
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
            fwupd
            killall
            doggo
            duf
            jqp
            xh
            fastfetch
            dmidecode
            usbutils
            pciutils
            gnumake
            e2fsprogs
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
            python3
            bun
            nmap
            arp-scan
            masscan
            whatweb
            difftastic
            ffmpeg
            imagemagick
            hexyl
            ssh-to-pgp
          ];
        };

        services = {
          upower.enable = true;
          dbus.enable = true;
          fwupd.enable = true;
          # Disable for now to avoid failed systemd
          # units (`bin.mount` and `usr-bin.mount`) on startup
          # envfs.enable = true;
        };

        hardware.graphics.enable = true;

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

        documentation = {
          enable = true;
          man.enable = true;
          man.man-db.enable = true;
          dev.enable = true;
        };
      };
    };

  flake.modules.homeManager.common =
    { lib, ... }:
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

        password-store = {
          enable = true;
          settings = {
            PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store";
          };
        };

        # DNS lookup failure on update during boot
        # tealdeer.enable = true;
      };
    };

}
