{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.wiggum =
    {
      lib,
      config,
      ...
    }:

    let
      inherit (config.sops) secrets;
    in
    {
      antob = {
        wireguard = {
          address = "10.64.1.5/24";
          privateKeyFile = secrets.wg0_private_key.path;
        };

        openssh = {
          listenAddresses = [ "10.64.1.5" ]; # bind to the wg0 IP
          interfaces = [ "wg0" ]; # open firewall only on wg0
        };

      };

      imports = with nixos; [
        server
        wireguard
      ];

      # Wait for the tunnel interfaces to be up before sshd binds
      systemd.services.sshd = {
        after = [ "wg-quick-wg0.service" ];
        wants = [ "wg-quick-wg0.service" ];
      };

      boot.kernel.sysctl = {
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
      };

      # No LLMNR or mDNS on a public host
      services.resolved.settings.Resolve = {
        LLMNR = false;
        MulticastDNS = false;
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
    };

  flake.nixosConfigurations.wiggum = inputs.nixpkgs.lib.nixosSystem { modules = [ nixos.wiggum ]; };
}
