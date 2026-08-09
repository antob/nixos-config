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
    ./fail2ban.nix
    ./caddy.nix
  ];

  antob = {
    features = {
      common-minimal = enabled;
    };

    hardware.networking.enable = mkForce false;

    services = {
      openssh = {
        enable = true;
        listenAddresses = [ "10.0.0.2" ]; # bind to the wg0 IP
        interfaces = [ "wg0" ]; # open firewall only on wg0
      };
      wireguard = {
        enable = true;
        address = "10.0.0.2/24";
        privateKeyFile = secrets.wg0_private_key.path;
      };
    };
  };

  # Wait for the tunnel interfaces to be up before sshd binds
  systemd.services.sshd = {
    after = [ "wg-quick-wg0.service" ];
    wants = [ "wg-quick-wg0.service" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  # Networking and firewall
  networking = {
    hostName = "wiggum";
    useNetworkd = true;
    firewall = {
      enable = true;
      allowPing = true;
    };
    nftables.enable = true;
    useDHCP = lib.mkForce false;
  };

  systemd.network = {
    enable = true;
    networks."30-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "ipv4";
      address = [
        "2a01:4f9:c013:a14a::/64"
      ];
      routes = [
        { Gateway = "fe80::1"; }
      ];
    };
  };

  # Bootloader.
  boot.loader = {
    grub.enable = true;
    systemd-boot.enable = false;
  };

  location = {
    latitude = 60.19;
    longitude = 24.95;
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
    secrets = {
      wg0_private_key = { };
    };
  };

  system.stateVersion = "22.11";
}
