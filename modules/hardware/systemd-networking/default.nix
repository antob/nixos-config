{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.hardware.systemd-networking;
in
{
  options.antob.hardware.systemd-networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable systemd networking support";
    hostName = mkOpt str "nixos" "The system host name.";
    hostId = mkOpt str "" "The system host ID.";
    enableWireless = mkBoolOpt true "Whether or not to enable wireless support";
    enableVpn = mkBoolOpt true "Whether or not to enable VPN config";
    staticIp = {
      enable = mkBoolOpt false "Whether or not to configure static IP on eth0";
      address = mkOpt str "" "Static IP address";
      dns = mkOpt (listOf str) [ ] "DNS adresses";
      gateway = mkOpt str "" "Gateway IP address";
    };
  };

  config = mkIf cfg.enable {
    antob = {
      hardware.networking.enable = mkForce false;
      services = {
        avahi.enable = mkForce false;
        networkd-vpn.enable = cfg.enableVpn;
      };
      persistence.directories = mkIf cfg.enableWireless [ "/var/lib/iwd" ];
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
      hostName = cfg.hostName;
      # Derived from `head -c 8 /etc/machine-id`
      hostId = cfg.hostId;

      # Wireless config
      wireless.iwd = mkIf cfg.enableWireless {
        enable = true;
        settings = {
          Settings = {
            AutoConnect = true;
          };
        };
      };
    };

    systemd.network = {
      enable = true;
      networks = {
        "10-lan" = {
          matchConfig.Name = "eth0";
          networkConfig.DHCP = "yes";
          linkConfig.RequiredForOnline = "no";

          address = mkIf cfg.staticIp.enable [ cfg.staticIp.address ];
          dns = mkIf cfg.staticIp.enable cfg.staticIp.dns;
          routes = mkIf cfg.staticIp.enable [
            { Gateway = cfg.staticIp.gateway; }
          ];

        };
        "10-wireless" = mkIf cfg.enableWireless {
          matchConfig.Name = "wlan0";
          networkConfig = {
            DHCP = "yes";
            IgnoreCarrierLoss = "3s";
          };
        };
      };
    };

    services.resolved.enable = true;

    # Do not wait for network connectivity (will timeout on nixos-rebuild)
    systemd.services.systemd-networkd-wait-online.enable = mkForce false;
  };
}
