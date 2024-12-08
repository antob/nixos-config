{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

with lib;
with lib.antob;

let
  secrets = config.sops.secrets;
  monCfg = config.antob.monitoring;
  emailFrom = monCfg.emailFrom;
  emailTo = monCfg.emailTo;
in
{
  imports = with inputs; [
    ./hardware.nix
    sops-nix.nixosModules.sops
    ./msmtp.nix
    ./nginx.nix
    ./podman.nix
    ./plex.nix
    ./mysql.nix
    ./photoprism.nix
    ./yopass.nix
    ./syncthing.nix
    ./homeassistant.nix
    ./esphome.nix
    ./nfsd.nix
    ./samba.nix
  ];

  antob = {
    features = {
      common = enabled;
      server = enabled;
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

    # gitea = {
    #   enable = true;
    # };
  };

  # Ensure folders in ZFS pool
  system.activationScripts.hyllan-zfs-setup.text = ''
    mkdir -p /mnt/tank/services
  '';

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
