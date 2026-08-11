{
  lib,
  config,
  inputs,
  ...
}:

with lib;
let
  secrets = config.sops.secrets;
in
{
  imports = with inputs; [
    kvmd.nixosModules.default
    kvmd.nixosModules.v2-hdmi-rpi4
    ./hardware.nix
  ];

  antob = {
    features.rpi = enabled;
    hardware.systemd-networking = {
      enable = true;
      enableWireless = false;
      enableVpn = false;
      hostName = "pikvm";
      # Derived from `head -c 8 /etc/machine-id`
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
    services.wireguard = {
      enable = true;
      address = "10.64.1.3/24";
      privateKeyFile = secrets.wg0_private_key.path;
    };
  };

  services.kvmd = {
    enable = true;
    janus.enable = true;
    # Install apacheHttpd for htpasswd command
    # htpasswd -5 -c filepath username
    htpasswdFile = secrets.pikvm_gui_htpasswd.path;
  };

  systemd.network.wait-online.enable = mkForce false;

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
}
