{ lib, config, options, ... }:

let
  cfg = config.antob.services.dhcpd;

  baseInternalIpList = lib.lists.sublist 1 3 (lib.strings.splitString "." cfg.internalIp);
  baseInternalIp = lib.strings.concatStringsSep "." baseInternalIpList;
  reverseBaseInternalIp = lib.strings.concatStringsSep "." (lib.lists.reverseList baseInternalIpList);

  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.antob) mkOpt;
in
{
  options.antob.services.dhcpd = with types; {
    enable = mkEnableOption "Enable Kea DCHP server";
    internalIp = mkOpt str "192.168.1.2" "The internal IP of the DHCP server.";
    internalDomain = mkOpt str "local" "The internal domain name.";
    interface = mkOpt str "eth0" "The network interface name.";
    dnsIp = mkOpt str "192.168.1.2" "The IP of the DNS server.";
  };

  config = mkIf cfg.enable {

    networking.firewall.allowedUDPPorts = [ 67 ];

    system.activationScripts.bind-zones.text = ''
      mkdir -p /var/lib/kea
      chown kea:kea /var/lib/kea
    '';

    services.kea = {
      dhcp4 = {
        enable = true;
        settings = {
          interfaces-config = {
            interfaces = [ cfg.interface ];
            dhcp-socket-type = "udp";
          };

          authoritative = true;

          lease-database = {
            name = "/var/lib/kea/dhcp4.leases";
            persist = true;
            type = "memfile";
            lfc-interval = 3600;
          };

          # NOTE: When changing the `valid-lifetime` setting make sure that
          # the `renew-timer` is set to 50% of `valid-lifetime` and the
          # `rebind-timer` is set to 87.5% of `valid-lifetime`.
          renew-timer = 15840;
          rebind-timer = 27720;
          valid-lifetime = 31680;

          option-data = [
            {
              name = "domain-name-servers";
              data = cfg.dnsIp;
              always-send = true;
            }
            {
              name = "domain-name";
              data = cfg.internalDomain;
            }
            {
              name = "routers";
              data = "${baseInternalIp}.1";
            }
          ];

          subnet4 = [
            {
              subnet = "${baseInternalIp}.0/24";

              pools = [
                {
                  pool = "${baseInternalIp}.100 - ${baseInternalIp}.199";
                }
              ];

              reservations = [
                {
                  hostname = "bender";
                  ip-address = "192.168.1.20";
                  hw-address = "c0:3f:d5:6b:00:07";
                }
              ];
            }
          ];
        };
      };

      dhcp-ddns = {
        enable = true;
        settings = {
          ip-address = "127.0.0.1";
          port = 53001;
          dns-server-timeout = 100;
          ncr-format = "JSON";
          ncr-protocol = "UDP";

          # control-socket = {
          #   socket-type = "unix";
          #   socket-name = "/tmp/kea-ddns-ctrl-socket";
          # };

          # tsig-keys = [ ];

          forward-ddns = {
            ddns-domains = [
              {
                name = cfg.internalDomain;
                # key-name = "dhcp1-ns1";
                dns-servers = [
                  { ip-address = cfg.dnsIp; }
                ];
              }
            ];
          };

          reverse-ddns = {
            ddns-domains = [
              {
                name = "${reverseBaseInternalIp}.in-addr.arpa.";
                # key-name = "dhcp1-ns1";
                dns-servers = [
                  { ip-address = cfg.dnsIp; }
                ];
              }
            ];
          };
        };
      };
    };
  };
}
