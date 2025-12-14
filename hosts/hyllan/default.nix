{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  monCfg = config.antob.monitoring;
  emailFrom = monCfg.emailFrom;
  emailTo = monCfg.emailTo;
  secrets = config.sops.secrets;
in
{
  imports = [
    ./hardware.nix
    ../../modules
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
    ./miniflux.nix
    ./vaultwarden.nix
    ./atuin.nix
    ./music-assistant.nix
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
          "1.1.1.1"
        ];
        gateway = "192.168.1.1";
      };
    };

    monitoring = {
      emailFrom = "home@antob.se";
      emailTo = "tob@antob.se";
    };

    services.tailscale = {
      enable = true;
      keyfile = secrets.tailscale_auth_key.path;
      extraUpFlags = [
        "--advertise-routes=192.168.1.0/24"
      ];
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

    caddy.antobProxies.pihole = {
      hostName = "192.168.1.4";
      port = 80;
      extraHandleConfig = ''
        rewrite / /admin
      '';
    };

    # Configure UDP GRO forwarding
    # See https://tailscale.com/s/ethtool-config-udp-gro
    networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = [ "routable" ];
        script = ''
          NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
          ${pkgs.ethtool}/bin/ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
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
    secrets = {
      zfs_encryption_key = { };
      tailscale_auth_key = { };
    };
  };

  environment.systemPackages = with pkgs; [
    libva # For hardware transcoding
    mosquitto
  ];

  system.stateVersion = "22.11";
}
