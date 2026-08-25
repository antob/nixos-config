{ config, pkgs, ... }:

let
  secrets = config.sops.secrets;
  iPhoneIp = "10.64.1.8";
in
{
  environment.systemPackages = [
    pkgs.wireguard-tools
    (pkgs.writeShellScriptBin "gen-wg-conf" ''
      set -e
      set -u

      endpoint=$(getent ahostsv4 wg.antob.se | awk 'NR==1 { print $1 }')
      [ -n "$endpoint" ] || { echo "DNS resolution failed" >&2; exit 1; }

      [ -r "$2" ] || { echo "Private key file not readable: $2" >&2; exit 1; }

      echo "Generating WireGuard configuration..."
      echo

      config="$(cat <<-EOF
        [Interface]
        PrivateKey = $(cat "$2")
        Address = $1
        DNS = 10.64.1.4

        [Peer]
        PublicKey = EvX7LhoS7FH6OI/EZBX4OPYnMk5ojKRvA/7Iu87FSnA=
        Endpoint = $endpoint:51820
        AllowedIPs = 10.64.1.0/24
        PersistentKeepalive = 25
      EOF
      )"
      echo "$config"
      echo

      ${pkgs.qrencode}/bin/qrencode -t ansiutf8 <<< "$config"
      echo
    '')
    (pkgs.writeShellScriptBin "gen-iphone-wg-conf" ''
      set -e
      set -u

      gen-wg-conf "${iPhoneIp}/24" "${secrets.iphone_wg_private_key.path}"
    '')
  ];

  networking = {
    firewall.allowedUDPPorts = [ 51820 ];
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1420";
        };
        wireguardConfig = {
          PrivateKeyFile = secrets.wg0_private_key.path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          # PiKVM
          {
            PublicKey = "w4KKlllk8xpQXoijHViqdefKw9Ilwcl9LJt7emP6GHg=";
            AllowedIPs = [ "10.64.1.3" ];
          }
          # Pi-hole
          {
            PublicKey = "70PciNESmE7cvtPuIORr/2paDCoTgokWoZbvblHyZGI=";
            AllowedIPs = [ "10.64.1.4" ];
          }
          # Wiggum
          {
            PublicKey = "dg98PnxFsAP04LS6m4HK/2knuqhlYMfNxtuaYH/YDHA=";
            AllowedIPs = [ "10.64.1.5" ];
          }
          # Desktob
          {
            PublicKey = "bnsImaGQClT8/kL/4BoyOcpmtlXi6deeyZeOJxiGljE=";
            AllowedIPs = [ "10.64.1.6" ];
          }
          # Laptob-fw
          {
            PublicKey = "9z3cCj7FV6S4JWhslfipclPrErGYjOvYGu3JJQ8Od0k=";
            AllowedIPs = [ "10.64.1.7" ];
          }
          # iPhone
          {
            PublicKey = "0scRw9cc8EKrjajRUYRcAsB/Gc2Pj1ww84Ot5/0bWmo=";
            AllowedIPs = [ iPhoneIp ];
          }
          # PiDesk
          {
            PublicKey = "ygE5P5AyxzGPZh5ljlaJ51pnBFOA2xyXRcfkqe92dBI=";
            AllowedIPs = [ "10.64.1.9" ];
          }
        ];
      };
    };
    networks.wg0 = {
      matchConfig.Name = "wg0";
      address = [ "10.64.1.2/24" ];
      dns = [ "10.64.1.4" ];
      networkConfig = {
        IPMasquerade = "ipv4";
        IPv4Forwarding = true;
        DNSDefaultRoute = true;
      };
    };
  };

  sops.secrets = {
    wg0_private_key = {
      owner = "systemd-network";
    };
    iphone_wg_private_key = { };
  };
}
