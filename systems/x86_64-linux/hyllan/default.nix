{ pkgs, config, lib, channel, inputs, ... }:

with lib;
with lib.antob;
{
  imports = [ ./hardware.nix ];

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
    services.bind = enabled;
  };

  services = {
    fstrim.enable = lib.mkDefault true;

    # plex = {
    #   enable = true;
    #   openFirewall = true;
    # };

    # photoprism = {
    #   enable = true;
    # };

    # gitea` = {
    #   enable = true;
    # };
  };

  # Networking
  networking = {
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
