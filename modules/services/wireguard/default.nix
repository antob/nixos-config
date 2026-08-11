{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.services.wireguard;
in
{
  options.antob.services.wireguard = with types; {
    enable = mkEnableOption "Whether or not to enable Wireguard.";
    privateKeyFile = mkOpt str "" "Path to this node's WireGuard private key file.";
    address = mkOpt str "" "IP address (CIDR) of this node in the mesh, e.g. 10.9.0.1/24.";
    dns = mkOpt str "10.64.1.4" "DNS server used to resolve tunnel-scoped domains via wg0.";
    domains = mkOpt (listOf str) [
      "~antob.net"
    ] "Route-only routing domains resolved through the tunnel.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.wg-quick.interfaces = {
      wg0 = {
        autostart = true;
        address = [ cfg.address ];
        privateKeyFile = cfg.privateKeyFile;

        # Scoped DNS: only cfg.domains route through the tunnel DNS. wg-quick's
        # `dns` option is intentionally NOT used here, because it installs a
        # catch-all routing domain (~.) on wg0, forcing ALL DNS through the tunnel.
        preDown = "${pkgs.systemd}/bin/resolvectl revert wg0";
        postUp = ''
          ${pkgs.systemd}/bin/resolvectl dns wg0 ${cfg.dns}
          ${pkgs.systemd}/bin/resolvectl domain wg0 ${concatStringsSep " " cfg.domains}
        '';

        peers = [
          # Hyllan
          {
            publicKey = "EvX7LhoS7FH6OI/EZBX4OPYnMk5ojKRvA/7Iu87FSnA=";
            allowedIPs = [
              "10.64.1.0/24"
            ];
            endpoint = "wg.antob.se:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
