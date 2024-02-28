{ pkgs, lib, inputs, ... }:

with lib;
with lib.antob;
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

    hardware.networking.enable = mkForce false;
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
      dns = [ "192.168.1.20" ];
      routes = [
        { routeConfig.Gateway = "192.168.1.1"; }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    libva # For hardware transcoding
  ];

  system.stateVersion = "22.11";
}
