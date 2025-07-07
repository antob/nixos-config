{
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}:

with lib;
{
  imports = with inputs; [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
    nur.modules.nixos.default
    ../../modules/nixos
  ];

  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  antob = {
    apps = {
      firefox = enabled;
      vscode = enabled;
    };

    tools = {
      alacritty = enabled;
      git = enabled;
      zsh = enabled;
      starship = enabled;
      eza = enabled;
      fzf = enabled;
    };

    cli-apps = {
      neovim = enabled;
      tmux = enabled;
    };

    hardware = {
      bluetooth = enabled;
      yubikey = enabled;
      networking = enabled;
      audio = enabled;
    };

    desktop.gnome = enabled;

    services = {
      openssh = enabled;
      printing = enabled;
    };

    security.gpg = enabled;

    system = {
      fonts = enabled;
      locale = enabled;
      time = enabled;
      console = enabled;
    };

    virtualisation.docker.enable = false;
    virtualisation.podman.enable = false;

    home.extraOptions.programs = {
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

  services = {
    upower.enable = true;
    dbus.enable = true;
  };

  location = {
    latitude = 57.7;
    longitude = 11.8;
  };

  environment.variables = {
    EDITOR = "nvim";
  };

  environment.shellAliases = {
    sudo = "sudo "; # Fixes missing alias doing `sudo`
    cat = "bat -p";
  };

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    gnome-calculator
    htop
    wget
    bottom
    ripgrep
    fd
    inetutils
    procs
    unzip
    fwupd
    killall
    dogdns
    dmidecode
    usbutils
    pciutils
    gnumake
    cifs-utils # Mount SMB shares
    file
  ];

  system.stateVersion = "22.11";
}
