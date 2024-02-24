{ pkgs, config, lib, channel, inputs, ... }:

with lib;
with lib.antob;
let
  secrets = config.sops.secrets;
  emailFrom = "home@antob.se";
  emailTo = "tob@antob.se";
in
{
  imports = with inputs; [
    ./hardware.nix
    sops-nix.nixosModules.sops
    ./plex.nix
  ];

  antob = {
    features = {
      common = enabled;
      server = enabled;
    };

    system.zfs = {
      enable = true;
      pools = [ "zpool" ];
      auto-snapshot.enable = false;
    };

    hardware.networking.enable = mkForce false;

    services = {
      bind = enabled;

      dhcpd = {
        enable = false;
        internalIp = "192.168.2.2";
        dnsIp = "192.168.1.20";
      };
    };
  };

  services = {
    fstrim.enable = lib.mkDefault true;

    smartd = {
      enable = true;
      notifications = {
        test = false;
        mail = {
          enable = true;
          sender = emailFrom;
          recipient = emailTo;
        };
      };
    };

    zfs.zed = {
      enableMail = true;
      settings = {
        ZED_EMAIL_ADDR = [ emailTo ];
        ZED_EMAIL_OPTS = "-a default @ADDRESS@";
        ZED_NOTIFY_VERBOSE = true;
      };
    };

    # photoprism = {
    #   enable = true;
    # };

    # gitea = {
    #   enable = true;
    # };
  };

  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = builtins.toFile "aliases" ''
        default: ${emailTo}
      '';
    };
    accounts.default = {
      auth = "plain";
      tls = "on";
      host = "smtp.protonmail.ch";
      port = "587";
      user = emailFrom;
      passwordeval = "${pkgs.coreutils}/bin/cat ${secrets.proton_smtp_token.path}";
      from = emailFrom;
    };
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.proton_smtp_token = { };
  };

  # Networking and firewall
  networking = {
    firewall.enable = true;
    nftables.enable = true;
    useDHCP = false;
    usePredictableInterfaceNames = false;
  };

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "eth0";
      address = [ "192.168.1.2/24" ];
      dns = [ "192.168.1.20" ];
      routes = [
        { routeConfig.Gateway = "192.168.1.1"; }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    libva # For hardware transcoding
  ];

  system.stateVersion = "22.11";
}
