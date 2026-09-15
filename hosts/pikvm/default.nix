{
  lib,
  config,
  ...
}:

with lib;
let
  secrets = config.sops.secrets;
in
{
  imports = [
    ./hardware.nix
  ];

  antob = {
    features.rpi = enabled;
    hardware.systemd-networking = {
      enable = true;
      hostName = "pikvm";
      enableWireless = false;
      enableVpn = false;
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
