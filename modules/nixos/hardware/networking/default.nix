{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.hardware.networking;
in
{
  options.antob.hardware.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support";
    hosts = mkOpt attrs { } "An attribute set to merge with <option>networking.hosts</option>";
  };

  config = mkIf cfg.enable {
    antob = {
      user.extraGroups = [ "networkmanager" ];
      persistence = {
        directories = [ "/etc/NetworkManager/system-connections" ];
        home.directories = [ ".cert" ];
      };
    };

    networking = {
      hosts = {
        "127.0.0.1" = (cfg.hosts."127.0.0.1" or [ ]);
      } // cfg.hosts;

      usePredictableInterfaceNames = false;

      networkmanager = {
        enable = true;
        dhcp = "internal";
        plugins = with pkgs; [
          networkmanager-openvpn
          pkgs.stable.networkmanager-l2tp
        ];
      };
    };

    services.strongswan = {
      enable = true;
      secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
    };

    services.dnsmasq = {
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

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
