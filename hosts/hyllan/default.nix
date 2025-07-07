{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

with lib;
let
  monCfg = config.antob.monitoring;
  emailFrom = monCfg.emailFrom;
  emailTo = monCfg.emailTo;
in
{
  imports = with inputs; [
    ./hardware.nix
    ../../modules/nixos
    sops-nix.nixosModules.sops
    ./msmtp.nix
    ./caddy.nix
    ./podman.nix
    ./plex.nix
    ./mysql.nix
    ./postgresql.nix
    ./photoprism.nix
    ./syncthing.nix
    ./homeassistant.nix
    ./esphome.nix
    ./nfsd.nix
    ./samba.nix
    ./fail2ban.nix
    ./miniflux.nix
    ./headscale.nix
  ];

  antob = {
    features = {
      common = enabled;
    };

    system.zfs = {
      enable = true;
      pools = [ "zpool" ];
      auto-snapshot.enable = false;
    };

    # Use custom setup for networking
    hardware.networking.enable = mkForce false;

    monitoring = {
      emailFrom = "home@antob.se";
      emailTo = "tob@antob.se";
    };
  };

  services = {
    fstrim.enable = mkDefault true;

    smartd = {
      enable = true;
      notifications = {
        test = false;
        mail = {
          enable = true;
          sender = emailFrom;
          recipient = emailTo;
        };
      };
    };

    zfs.zed = {
      enableMail = true;
      settings = {
        ZED_EMAIL_ADDR = [ emailTo ];
        ZED_EMAIL_OPTS = "-a default @ADDRESS@";
        ZED_NOTIFY_VERBOSE = true;
      };
    };

    caddy.antobProxies.pihole = {
      hostName = "192.168.1.4";
      port = 80;
      extraHandleConfig = ''
        rewrite / /admin
      '';
    };
  };

  # Ensure folders in ZFS pool
  systemd.tmpfiles.rules = [
    "d /mnt/tank/services 0755 root root -"
  ];

  # Networking and firewall
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
    };
    nftables.enable = true;
    useDHCP = false;
    usePredictableInterfaceNames = false;
  };

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "eth0";
      address = [ "192.168.1.2/24" ];
      dns = [
        "192.168.1.4"
        "1.1.1.1"
      ];
      routes = [
        { Gateway = "192.168.1.1"; }
      ];
    };
  };

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      configurationLimit = 5;
      editor = false;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.zfs_encryption_key = { };
  };

  environment.systemPackages = with pkgs; [
    libva # For hardware transcoding
    mosquitto
  ];

  system.stateVersion = "22.11";
}
