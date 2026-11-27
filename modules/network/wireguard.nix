{ config, ... }:
let
  inherit (config.flake.lib) mkOpt mkBoolOpt;

  nodes = {
    hyllan = {
      ip = "10.64.1.2";
      publicKey = "EvX7LhoS7FH6OI/EZBX4OPYnMk5ojKRvA/7Iu87FSnA=";
    };
    pikvm = {
      ip = "10.64.1.3";
      publicKey = "w4KKlllk8xpQXoijHViqdefKw9Ilwcl9LJt7emP6GHg=";
    };
    pihole = {
      ip = "10.64.1.4";
      publicKey = "70PciNESmE7cvtPuIORr/2paDCoTgokWoZbvblHyZGI=";
    };
    wiggum = {
      ip = "10.64.1.5";
      publicKey = "kXis0LY2yJ9xmauVtbd0XvGGOFpgUU0etPHB//1JCQ0=";
    };
    desktob = {
      ip = "10.64.1.6";
      publicKey = "bnsImaGQClT8/kL/4BoyOcpmtlXi6deeyZeOJxiGljE=";
    };
    laptob = {
      ip = "10.64.1.7";
      publicKey = "9z3cCj7FV6S4JWhslfipclPrErGYjOvYGu3JJQ8Od0k=";
    };
    iphone = {
      ip = "10.64.1.8";
      publicKey = "0scRw9cc8EKrjajRUYRcAsB/Gc2Pj1ww84Ot5/0bWmo=";
    };
    pidesk = {
      ip = "10.64.1.9";
      publicKey = "ygE5P5AyxzGPZh5ljlaJ51pnBFOA2xyXRcfkqe92dBI=";
    };
  };

  hub = "hyllan";
  subnet = "10.64.1.0/24";
  port = 51820;
  hubEndpoint = "wg.antob.se:${toString port}";
in
{
  flake.modules.nixos.wireguard =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.wireguard;
      node = nodes.${cfg.name};

      hubPeers = mapAttrsToList (_: n: {
        inherit (n) publicKey;
        allowedIPs = [ "${n.ip}/32" ];
      }) (removeAttrs nodes [ cfg.name ]);

      spokePeers = [
        {
          inherit (nodes.${hub}) publicKey;
          allowedIPs = [ subnet ];
          endpoint = hubEndpoint;
          persistentKeepalive = 25;
        }
      ];
    in
    {
      options.antob.wireguard = with types; {
        name = mkOpt (enum (
          attrNames nodes
        )) config.networking.hostName "This node's name in the mesh table.";
        hub = mkBoolOpt false "Whether this node is a wg0 hub that peers with every node and forwards between them.";
        privateKeyFile =
          mkOpt str config.sops.secrets.wg0_private_key.path
            "Path to this node's WireGuard private key file.";
        address = mkOpt str "${node.ip}/24" "IP address (CIDR) of this node in the mesh.";
        dns = mkOpt str nodes.pihole.ip "DNS server used to resolve tunnel-scoped domains via wg0.";
        domains = mkOpt (listOf str) [
          "~antob.net"
        ] "Route-only routing domains resolved through the tunnel.";
      };

      config = mkMerge [
        {
          environment.systemPackages = [ pkgs.wireguard-tools ];

          # The key file path does not change when the key is rotated.
          sops.secrets.wg0_private_key.restartUnits = [ "wg-quick-wg0.service" ];

          # If the tunnel fails to start, retry rather than fail permanently.
          systemd.services.wg-quick-wg0 = {
            serviceConfig = {
              Restart = "on-failure";
              RestartSec = 5;
            };
          };

          networking.wg-quick.interfaces = {
            wg0 = {
              autostart = true;
              address = [ cfg.address ];
              inherit (cfg) privateKeyFile;

              # Scoped DNS: only cfg.domains route through the tunnel DNS. wg-quick's
              # `dns` option would install a catch-all routing domain (~.) on wg0.
              preDown = "${pkgs.systemd}/bin/resolvectl revert wg0";
              postUp = ''
                ${pkgs.systemd}/bin/resolvectl dns wg0 ${cfg.dns}
                ${pkgs.systemd}/bin/resolvectl domain wg0 ${concatStringsSep " " cfg.domains}
              '';

              peers = if cfg.hub then hubPeers else spokePeers;
            };
          };
        }

        (mkIf cfg.hub {
          networking.wg-quick.interfaces.wg0.listenPort = port;
          networking.firewall = {
            allowedUDPPorts = [ port ];
            filterForward = true;
            extraForwardRules = ''
              iifname "wg0" oifname "wg0" accept
            '';
          };
          boot.kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            # Spokes reach each other only through the hub, redirects would be wrong
            "net.ipv4.conf.all.send_redirects" = 0;
            "net.ipv4.conf.default.send_redirects" = 0;
          };
        })
      ];
    };
}
