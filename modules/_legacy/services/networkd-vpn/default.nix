{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.services.networkd-vpn;
  inherit (config.sops) secrets;
in
{
  options.antob.services.networkd-vpn = with types; {
    enable = mkEnableOption "Whether or not to enable VPN via networkd.";

    vpns = mkOption {
      type = attrsOf (submodule {
        options = {
          type = mkOption {
            type = enum [
              "systemd"
              "snx"
            ];
            default = "systemd";
            description = ''
              How the VPN is controlled. `systemd` starts/stops `unitName`,
              `snx` connects/disconnects the snx-rs profile `snxProfile`.
            '';
          };
          unitName = mkOption {
            type = nullOr str;
            default = null;
            description = "Systemd unit name (type `systemd`).";
          };
          snxProfile = mkOption {
            type = nullOr str;
            default = null;
            description = "snx-rs profile name or UUID (type `snx`).";
          };
          label = mkOption {
            type = str;
            description = "Display label of the VPN.";
          };
        };
      });
      default = { };
      example = literalExpression ''
        {
          "mullvad0" = {
            unitName = "wg-quick-mullvad0";
            label = "Mullvad";
          };
          "snx-work" = {
            type = "snx";
            snxProfile = "Work";
            label = "Work";
          };
        };
      '';
      description = ''
        Declarative specification of vpn interfaces. The attribute name must
        match the network interface the VPN creates; it is used to detect
        whether the VPN is active.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = mapAttrsToList (name: vpn: {
      assertion = if vpn.type == "systemd" then vpn.unitName != null else vpn.snxProfile != null;
      message = "antob.services.networkd-vpn.vpns.${name}: type `${vpn.type}` requires `${
        if vpn.type == "systemd" then "unitName" else "snxProfile"
      }` to be set.";
    }) cfg.vpns;

    antob.services.networkd-vpn.vpns = {
      protonvpn0 = {
        label = "Proton VPN (Sweden)";
        unitName = "wg-quick-protonvpn0";
      };
      protonvpn1 = {
        label = "Proton VPN (US/New York)";
        unitName = "wg-quick-protonvpn1";
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
      protonvpn1 = {
        autostart = false;
        address = [ "10.2.0.2/32" ];
        dns = [ "10.2.0.1" ];
        privateKeyFile = secrets.protonvpn1_private_key.path;

        peers = [
          {
            publicKey = "XsJ968M1eNOuehhnuFTAtlTpzQfyFLpYTzo3L6Xe8EA=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "89.187.179.55:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };

    sops.secrets = {
      protonvpn0_private_key = { };
      protonvpn1_private_key = { };
    };
  };
}
