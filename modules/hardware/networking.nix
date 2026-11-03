{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  flake.modules.nixos.networking =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    let
      cfg = config.antob.networking;
    in
    {
      options.antob.networking = with types; {
        hosts = mkOpt attrs { } "An attribute set to merge with <option>networking.hosts</option>";
      };

      config = {
        antob = {
          user.extraGroups = [ "networkmanager" ];
          persistence.safe = {
            directories = [ "/etc/NetworkManager/system-connections" ];
            files = [ "/etc/ipsec.d/ipsec.nm-l2tp.secrets" ];
            home.directories = [ ".cert" ];
          };
        };

        networking = {
          hosts = {
            "127.0.0.1" = cfg.hosts."127.0.0.1" or [ ];
          }
          // cfg.hosts;

          usePredictableInterfaceNames = false;

          networkmanager = {
            enable = true;
            dhcp = "internal";
            plugins = with pkgs; [
              networkmanager-openvpn
              networkmanager-l2tp
              networkmanager_strongswan
            ];
          };
        };

        services = {
          strongswan = {
            enable = true;
            secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
          };

          dnsmasq = {
            enable = true;
            settings = {
              address = "/.test/127.0.0.1";
              listen-address = [
                "::1"
                "127.0.0.1"
              ];
              bind-interfaces = true;
            };
          };

          resolved.enable = true;
        };

        # Workaround to fix l2tp. See https://github.com/NixOS/nixpkgs/issues/375352
        environment.etc."strongswan.conf".text = "";

        systemd = {
          tmpfiles.rules = [
            "d /etc/ipsec.d 0700 root root -"
          ];

          # Fixes an issue that normally causes nixos-rebuild to fail.
          # https://github.com/NixOS/nixpkgs/issues/180175
          services.NetworkManager-wait-online.enable = false;

          # Stop wpa_supplicant service spamming logs with "CTRL-EVENT-SIGNAL-CHANGE" messages.
          services.wpa_supplicant.serviceConfig.LogLevelMax = "warning";
        };

        # 2;
      };
    };

}
