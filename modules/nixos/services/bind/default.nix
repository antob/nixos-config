{ lib, config, options, ... }:

let
  cfg = config.antob.services.bind;

  dnsHostIpLast = lib.lists.last (lib.strings.splitString "." cfg.dnsHostIp);
  zoneNetworkBase = lib.lists.head (lib.strings.splitString "/" cfg.zoneNetwork);
  zoneReverseNetwork = lib.strings.concatStringsSep "." (lib.lists.reverseList (lib.strings.splitString "." zoneNetworkBase));

  inherit (lib) types mkEnableOption mkIf mkForce;
  inherit (lib.antob) mkOpt;
in
{
  options.antob.services.bind = with types; {
    enable = mkEnableOption "Enable Bind";
    dnsHostName = mkOpt str "hyllan" "The host name of the LAN DNS server.";
    dnsHostIp = mkOpt str "192.168.1.2" "The IP of the LAN DNS server.";
    zoneName = mkOpt str "antob.lan" "The name of the LAN DNS zone.";
    zoneNetwork = mkOpt str "192.168.1/24" "The network class of the LAN DNS zone.";
  };

  config = mkIf cfg.enable {
    services.dnsmasq.enable = mkForce false;

    services.bind = {
      enable = true;
      ipv4Only = true;
      forwarders = [ ];
      cacheNetworks = [
        "localhost"
        cfg.zoneNetwork
      ];

      extraOptions = ''
        allow-query-cache { cachenetworks; };
        allow-recursion { none; };
        allow-transfer { none; };

        check-names master ignore;
        check-names slave ignore;
        check-names response ignore;

        notify no;
      '';

      extraConfig = ''
        server ::/0 {
            bogus yes;
        };
      '';

      zones = {
        "antob.lan" = {
          master = true;
          file = "/etc/bind/zones/${cfg.zoneName}.zone";
        };

        "${zoneReverseNetwork}.in-addr.arpa" = {
          master = true;
          file = "/etc/bind/zones/${zoneReverseNetwork}.rev";
        };
      };
    };

    networking.firewall.allowedUDPPorts = [ 53 ];

    system.activationScripts.bind-zones.text = ''
      mkdir -p /etc/bind/zones
      chown named:named /etc/bind/zones
    '';

    environment.etc."bind/zones/${cfg.zoneName}.zone" = {
      enable = true;
      user = "named";
      group = "named";
      mode = "0644";
      text = ''
        $ORIGIN .
        $TTL 907200     ; 1 week 3 days 12 hours
        ${cfg.zoneName}             IN SOA  ${cfg.dnsHostName}.${cfg.zoneName}. webmaster.${cfg.zoneName}. (
                                        1263529355 ; serial
                                        10800      ; refresh (3 hours)
                                        3600       ; retry (1 hour)
                                        604800     ; expire (1 week)
                                        38400      ; minimum (10 hours 40 minutes)
                                        )
                                NS      ${cfg.dnsHostName}.${cfg.zoneName}.
        $ORIGIN ${cfg.zoneName}.
        gateway              A       ${zoneNetworkBase}.1
        ${cfg.dnsHostName}       A       ${cfg.dnsHostIp}
      '';
    };

    environment.etc."bind/zones/${zoneReverseNetwork}.rev" = {
      enable = true;
      user = "named";
      group = "named";
      mode = "0644";
      text = ''
        $ORIGIN .
        $TTL 907200     ; 1 week 3 days 12 hours
        ${zoneReverseNetwork}.in-addr.arpa   IN SOA  ${cfg.dnsHostName}.${cfg.zoneName}. webmaster.${cfg.zoneName}. (
                                        1263189277 ; serial
                                        10800      ; refresh (3 hours)
                                        3600       ; retry (1 hour)
                                        604800     ; expire (1 week)
                                        38400      ; minimum (10 hours 40 minutes)
                                        )
                                NS      ${cfg.dnsHostName}.${cfg.zoneName}.
        $ORIGIN ${zoneReverseNetwork}.in-addr.arpa.
        1                       PTR     gateway.${cfg.zoneName}.
        ${dnsHostIpLast}        PTR     ${cfg.dnsHostName}.${cfg.zoneName}.
      '';
    };
  };
}
