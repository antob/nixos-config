{
  lib,
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
      address = "10.0.0.7/24";
      privateKeyFile = secrets.wg0_private_key.path;
    };
  };

  services.kvmd = {
    enable = true;
    janus.enable = true;
    htpasswdFile = secrets.pikvm_gui_password.path;
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      wg0_private_key = {
        owner = "systemd-network";
      };
      pikvm_gui_password = { };
    };
  };

  system.stateVersion = "21.11";
}
