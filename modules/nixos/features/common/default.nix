{ options, config, lib, pkgs, ... }:

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
        git = enabled;
        zsh = enabled;
        starship = enabled;
        eza = enabled;
        direnv = enabled;
        devenv = enabled;
        zellij = enabled;
        rustup = enabled;
        mcfly = enabled;
      };

      cli-apps = {
        neovim = enabled;
        helix = enabled;
        tmux = enabled;
      };

      # virtualisation.podman = enabled;
      virtualisation.docker = enabled;

      hardware = {
        networking = enabled;
        audio = enabled;
      };

      services = {
        openssh = enabled;
        avahi = enabled;
        printing = enabled;
        syncthing = enabled;
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
          config.theme = "ansi";
        };

        password-store.enable = true;

        # DNS lookup failure on update during boot
        # tealdeer.enable = true;
      };
    };

    environment.shellAliases = {
      cat = "bat -p";
      http = "xh";
      https = "xhs";
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
      tailspin
      gnumake
      cifs-utils # Mount SMB shares
    ];

    services = {
      upower.enable = true;
      dbus.enable = true;
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
