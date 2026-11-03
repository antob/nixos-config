{ config, ... }:
let
  inherit (config.flake.lib) mkOpt mkBoolOpt;
in
{
  flake.modules.nixos.systemd-networking =
    {
      config,
      lib,
      ...
    }:

    with lib;
    let
      cfg = config.antob.systemd-networking;
    in
    {
      options.antob.systemd-networking = with types; {
        hostName = mkOpt str "nixos" "The system host name.";
        hostId = mkOpt str "" "The system host ID.";
        enableWireless = mkBoolOpt true "Whether or not to enable wireless support";
        enableWoL = mkBoolOpt false "Whether or not to enable Wake-on-LAN on eth0";
        staticIp = {
          enable = mkBoolOpt false "Whether or not to configure static IP on eth0";
          address = mkOpt str "" "Static IP address";
          dns = mkOpt (listOf str) [ ] "DNS adresses";
          gateway = mkOpt str "" "Gateway IP address";
        };
      };

      config = {
        antob = {
          persistence.safe.directories = mkIf cfg.enableWireless [ "/var/lib/iwd" ];
        };

        # Networking and firewall
        networking = {
          firewall = {
            enable = true;
            allowPing = true;
            allowedUDPPorts = [ 5353 ];
          };
          nftables.enable = true;
          useNetworkd = true;
          networkmanager.enable = false;
          useDHCP = false;
          usePredictableInterfaceNames = false;
          hostName = cfg.hostName;
          hostId = cfg.hostId;

          # Wake-on-LAN policy on the wired interface.
          interfaces.eth0.wakeOnLan = mkIf cfg.enableWoL {
            enable = true;
            policy = [ "magic" ];
          };

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
              networkConfig = {
                DHCP = if cfg.staticIp.enable then "no" else "yes";
                MulticastDNS = true;
              };
              linkConfig.RequiredForOnline = "yes";

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
                MulticastDNS = true;
              };
            };
          };
        };

        services.resolved.enable = true;

        # Wait for at least one link (wired or wireless) to be online before
        # declaring the network ready.
        systemd.network.wait-online = {
          enable = true;
          anyInterface = true;
          timeout = 30;
        };
      };
    };

}
