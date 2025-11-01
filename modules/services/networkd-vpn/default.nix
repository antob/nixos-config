{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.services.networkd-vpn;
  secrets = config.sops.secrets;
in
{
  options.antob.services.networkd-vpn = with types; {
    enable = mkEnableOption "Whether or not to enable VPN via networkd.";

    vpns = mkOption {
      type = attrsOf (submodule {
        unitName = mkOption {
          type = str;
          description = "Systemd unit name.";
        };
        label = mkOption {
          type = str;
          description = "Display label of the VPN.";
        };
      });
      default = { };
      example = literalExpression ''
        {
          "mullvad0" = {
            unitName = "wg-quick-mullvad0";
            label = "Mullvad";
          };
        };
      '';
      description = "Declarative specification of vpn interfaces.";
    };
  };

  config = mkIf cfg.enable {
    antob.services.networkd-vpn.vpns = {
      protonvpn0 = {
        label = "Proton VPN (Sweden)";
        unitName = "wg-quick-protonvpn0";
      };
    };

    networking.wg-quick.interfaces = {
      protonvpn0 = {
        autostart = false;
        address = [ "10.2.0.2/32" ];
        dns = [ "10.2.0.1" ];
        privateKeyFile = secrets.protonvpn0_private_key.path;

        peers = [
          {
            publicKey = "IjsYenMdJFqbaNdVDx9t9NROTkA4EHBpXVejC36E1Wk=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "62.93.166.122:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };

    sops.secrets = {
      protonvpn0_private_key = { };
    };
  };
}
