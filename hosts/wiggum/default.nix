{
  lib,
  inputs,
  ...
}:

with lib;
{
  imports = with inputs; [
    disko.nixosModules.disko
    sops-nix.nixosModules.sops
    simple-nixos-mailserver.nixosModule
    ./hardware.nix
    ../../modules
    ./fail2ban.nix
    ./caddy.nix
    ./headscale.nix
    ./mailserver.nix
    ./webmail.nix
  ];

  antob = {
    features = {
      common = enabled;
    };

    tools = {
      fhs = enabled;
    };

    system.console.setFont = mkForce false;
    hardware.networking.enable = mkForce false;

    # Disable SSH connectivity. Connect through Tailscale only.
    services.openssh.enable = mkForce false;
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
  boot.loader.grub.enable = true;

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
  };

  system.stateVersion = "22.11";
}
