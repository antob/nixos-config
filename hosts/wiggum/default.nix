{
  pkgs,
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
    disko.nixosModules.disko
    sops-nix.nixosModules.sops
    ./hardware.nix
    ../../modules
  ];

  antob = {
    features = {
      common = enabled;
    };

    tools = {
      fhs = enabled;
    };

    system.console.setFont = mkForce false;

    services.tailscale = {
      enable = true;
      keyfile = secrets.tailscale_auth_key.path;
      extraUpFlags = [
        "--advertise-exit-node"
      ];
    };
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
    firewall = {
      enable = true;
      allowPing = true;
    };
    nftables.enable = true;
    useDHCP = lib.mkForce false;
  };

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      configurationLimit = 5;
      editor = false;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.tailscale_auth_key = { };
  };

  system.stateVersion = "22.11";
}
