{ pkgs, config, lib, channel, inputs, ... }:

with lib; {
  imports = [ ./hardware.nix ];

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

  services = {
    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";
    };

    upower.enable = true;
    dbus.enable = true;

    # Spice VDA
    # spice-vdagentd.enable = true;
  };

  antob = {
    user = {
      name = "tob";
      fullName = "Tobias Lindholm";
      email = "tobias.lindholm@antob.se";
      hashedPassword =
        "$y$j9T$wjUKjUTgvrxCg7HVJIrl2/$A0nvjyLzv869pQYmjyuIgXafrZDk2Lzg9B/nA/W4609";
      autoLogin = true;
    };

    desktop.xfce-xmonad = enabled;

    apps = {
      alacritty = enabled;
      firefox = enabled;
      librewolf = enabled;
      vscodium = enabled;
      slack = enabled;
    };

    services = {
      openssh = enabled;
      avahi = enabled;
      printing = enabled;
      syncthing = enabled;
      redshift = enabled;
    };

    hardware = {
      fingerprint = enabled;
      networking = enabled;
      bluetooth = enabled;
      audio = enabled;
    };

    system = {
      time = enabled;
      locale = enabled;
      console = enabled;
      fonts = enabled;
    };

    persistence = {
      enable = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/backlight"
      ];
      files = [
        "/etc/machine-id"
        "/ssh/ssh_host_rsa_key"
        "/ssh/ssh_host_rsa_key.pub"
        "/ssh/ssh_host_ed25519_key"
        "/ssh/ssh_host_ed25519_key.pub"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /persist/var/log 0755 root root -"
    "d /persist/var/lib/nixos 0755 root root -"
    "d /persist/var/lib/systemd/coredump 0755 root root -"
    "d /mnt 0755 root root -"
  ];

  environment.systemPackages = with pkgs; [
    htop
    wget
    bottom
    ripgrep
    fd
    dconf2nix
    jq
    rustc
    cargo
    rustfmt
    clippy
    gcc
    inetutils
    gnumake
    powertop
    procs
    unzip
    du-dust
    arandr
    chromium
    libreoffice-still
    fwupd
    killall
    dogdns
    duf
    jqp
    xh
    vulkan-tools
    glxinfo
    clinfo
    libva-utils
    python39
  ];

  system.stateVersion = "22.11";
}
