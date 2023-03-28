{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.hardware.networking;
in {
  options.antob.hardware.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support";
    hosts = mkOpt attrs { }
      "An attribute set to merge with <option>networking.hosts</option>";
  };

  config = mkIf cfg.enable {
    antob.user.extraGroups = [ "networkmanager" ];
    antob.persistence.directories =
      [ "/etc/NetworkManager/system-connections" ];

    networking = {
      hosts = {
        "127.0.0.1" = [ "local.test" ] ++ (cfg.hosts."127.0.0.1" or [ ]);
      } // cfg.hosts;

      networkmanager = {
        enable = true;
        dhcp = "internal";
        plugins = with pkgs; [ networkmanager-openvpn networkmanager-l2tp ];
      };
    };

    services.strongswan = {
      enable = true;
      secrets = [ "ipsec.d/ipsec.nm-l2tp.secrets" ];
    };

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
