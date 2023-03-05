{ config, lib, ... }:

with lib;
with types;

let cfg = config.host.hardware.networking;

in {
  options.host = {
    name = mkOption {
      type = str;
      default = "laptob";
      description = "Hostname";
    };

    hardware.networking = {
      enable = mkEnableOption "Whether or not to enable networking support";
      hosts = mkOption {
        type = attrs;
        default = { };
        description =
          "An attribute set to merge with <option>networking.hosts</option>";
      };
    };
  };

  config = mkIf cfg.enable {
    host.user.extraGroups = [ "networkmanager" ];

    networking = {
      hostName = config.host.name;

      hosts = {
        "127.0.0.1" = [ "local.test" ] ++ (cfg.hosts."127.0.0.1" or [ ]);
      } // cfg.hosts;

      networkmanager = {
        enable = true;
        dhcp = "internal";
      };
    };

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
