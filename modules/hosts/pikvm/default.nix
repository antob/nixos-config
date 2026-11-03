{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.pikvm =
    {
      lib,
      config,
      ...
    }:

    let
      inherit (config.sops) secrets;
    in
    {
      antob.systemd-networking = {
        hostName = "pikvm";
        enableWireless = false;
        hostId = "e3df0975";
        staticIp = {
          enable = true;
          address = "192.168.1.3/24";
          dns = [
            "192.168.1.4"
          ];
          gateway = "192.168.1.1";
        };
      };

      antob.wireguard = {
        address = "10.64.1.3/24";
        privateKeyFile = secrets.wg0_private_key.path;
      };

      imports = [
        nixos.rpi
        nixos.wireguard
        nixos.systemd-networking
        nixos.base
      ];

      services.kvmd = {
        enable = true;
        janus.enable = true;
        # Install apacheHttpd for htpasswd command
        # htpasswd -5 -c filepath username
        htpasswdFile = secrets.pikvm_gui_htpasswd.path;
      };

      # Sops secrets
      sops = {
        defaultSopsFile = ./secrets.yaml;
        secrets = {
          wg0_private_key = {
            owner = "systemd-network";
          };
          pikvm_gui_htpasswd = {
            owner = "kvmd";
          };
        };
      };

      system.stateVersion = "21.11";
    };

  flake.nixosConfigurations.pikvm = inputs.nixos-raspberrypi.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [ nixos.pikvm ];
  };
}
