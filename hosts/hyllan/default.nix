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
  imports = [
    inputs.copyparty.nixosModules.default
    ./hardware.nix
    ./msmtp.nix
    ./caddy.nix
    ./podman.nix
    ./mysql.nix
    ./postgresql.nix
    ./photoprism.nix
    ./syncthing.nix
    ./homeassistant.nix
    ./esphome.nix
    ./nfsd.nix
    ./samba.nix
    ./miniflux.nix
    ./vaultwarden.nix
    ./atuin.nix
    ./music-assistant.nix
    ./beszel.nix
    ./open-webui.nix
    ./copyparty.nix
    ./wireguard.nix
    ./backup.nix
    ./restic-server.nix
    ./nix-cache.nix
  ];

  antob = {
    features = {
      common = enabled;
    };

    tools.atuin = {
      enable = true;
      autoSync = false;
      filterMode = "host";
    };

    system.zfs = {
      enable = true;
      pools = [ "zpool" ];
      auto-snapshot.enable = false;
    };

    virtualisation.docker.storageDriver = "btrfs";

    hardware.systemd-networking = {
      enable = true;
      enableWireless = false;
      enableVpn = false;
      hostName = "hyllan";
      # Derived from `head -c 8 /etc/machine-id`
      hostId = "236689a3";
      staticIp = {
        enable = true;
        address = "192.168.1.2/24";
        dns = [
          "192.168.1.4"
        ];
        gateway = "192.168.1.1";
      };
    };

    monitoring = {
      emailFrom = "home@antob.se";
      emailTo = "tob@antob.se";
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
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

    caddy.antobProxies."pihole-web" = {
      hostName = "192.168.1.4";
      port = 80;
    };
  };

  # Ensure folders in ZFS pool
  systemd.tmpfiles.rules = [
    "d /mnt/tank/services 0755 root root -"
  ];

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      zfs_encryption_key = { };
    };
  };

  environment.systemPackages = with pkgs; [
    libva # For hardware transcoding
    mosquitto
  ];

  system.stateVersion = "22.11";
}
