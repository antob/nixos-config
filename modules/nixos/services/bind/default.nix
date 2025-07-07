{
  lib,
  config,
  ...
}:

let
  cfg = config.antob.services.bind;

  internalIpLast = lib.lists.last (lib.strings.splitString "." cfg.internalIp);
  hostFqdn = "${cfg.hostName}.${cfg.internalDomain}";
  baseInternalNetwork = lib.lists.head (lib.strings.splitString "/" cfg.internalNetwork);
  reverseBaseInternalNetwork = lib.strings.concatStringsSep "." (
    lib.lists.reverseList (lib.strings.splitString "." baseInternalNetwork)
  );

  inherit (lib)
    types
    mkEnableOption
    mkIf
    mkForce
    mkOpt
    ;
in
{
  options.antob.services.bind = with types; {
    enable = mkEnableOption "Enable Bind";
    hostName = mkOpt str "hyllan" "The host name of the LAN DNS server.";
    internalIp = mkOpt str "192.168.1.4" "The internal IP of the DNS server.";
    internalDomain = mkOpt str "local" "The internal domain name.";
    internalNetwork = mkOpt str "192.168.1/24" "The network class of the LAN DNS zone.";
  };

  config = mkIf cfg.enable {
    services.dnsmasq.enable = mkForce false;

    services.bind = {
      enable = true;
      ipv4Only = true;
      forwarders = [ ];
      cacheNetworks = [
        "localhost"
        cfg.internalNetwork
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
        "${cfg.internalDomain}" = {
          master = true;
          file = "/etc/bind/zones/${cfg.internalDomain}.zone";
          extraConfig = ''
            # allow-update { key rndc-key; };
            update-policy {
              grant rndc-key wildcard *.${cfg.internalDomain} A DHCID;
            };
          '';
        };

        "${reverseBaseInternalNetwork}.in-addr.arpa" = {
          master = true;
          file = "/etc/bind/zones/${reverseBaseInternalNetwork}.rev";
          extraConfig = ''
            # allow-update { key rndc-key; };
            # update-policy {
            #   grant rndc-key wildcard *.${reverseBaseInternalNetwork}.in-addr.arpa PTR DHCID;
            # };
            allow-update { ${cfg.internalIp}; };
          '';
        };
      };
    };

    networking.firewall.allowedUDPPorts = [ 53 ];

    system.activationScripts.bind-zones.text = ''
      mkdir -p /etc/bind/zones
      chown named:named /etc/bind/zones
    '';

    environment.etc."bind/zones/${cfg.internalDomain}.zone" = {
      enable = true;
      user = "named";
      group = "named";
      mode = "0644";
      text = ''
        $ORIGIN .
        $TTL 907200     ; 1 week 3 days 12 hours
        ${cfg.internalDomain}           IN SOA  ${hostFqdn}. webmaster.${cfg.internalDomain}. (
                                        1263529355 ; serial
                                        10800      ; refresh (3 hours)
                                        3600       ; retry (1 hour)
                                        604800     ; expire (1 week)
                                        38400      ; minimum (10 hours 40 minutes)
                                        )
                                NS      ${hostFqdn}.
        $ORIGIN ${cfg.internalDomain}.
        gateway                 A       ${baseInternalNetwork}.1
        ${cfg.hostName}         A       ${cfg.internalIp}
      '';
    };

    environment.etc."bind/zones/${reverseBaseInternalNetwork}.rev" = {
      enable = true;
      user = "named";
      group = "named";
      mode = "0644";
      text = ''
        $ORIGIN .
        $TTL 907200     ; 1 week 3 days 12 hours
        ${reverseBaseInternalNetwork}.in-addr.arpa   IN SOA  ${hostFqdn}. webmaster.${cfg.internalDomain}. (
                                        1263189277 ; serial
                                        10800      ; refresh (3 hours)
                                        3600       ; retry (1 hour)
                                        604800     ; expire (1 week)
                                        38400      ; minimum (10 hours 40 minutes)
                                        )
                                NS      ${hostFqdn}.
        $ORIGIN ${reverseBaseInternalNetwork}.in-addr.arpa.
        1                       PTR     gateway.${cfg.internalDomain}.
        ${internalIpLast}       PTR     ${hostFqdn}.
      '';
    };
  };
}
