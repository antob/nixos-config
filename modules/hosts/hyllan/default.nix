{ config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.hyllan =
    {
      pkgs,
      lib,
      config,
      inputs,
      ...
    }:

    with lib;
    let
      monCfg = config.antob.monitoring;
      emailFrom = monCfg.emailFrom;
      emailTo = monCfg.emailTo;
    in
    {
      antob.systemd-networking = {
        enableWireless = false;
        hostName = "hyllan";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "236689a3";
        staticIp = {
          enable = true;
          address = "192.168.1.2/24";
          dns = [
            "192.168.1.4"
          ];
          gateway = "192.168.1.1";
        };
      };

      antob.zfs = {
        pools = [ "zpool" ];
        auto-snapshot.enable = false;
      };

      antob.atuin = {
        autoSync = false;
        filterMode = "host";
      };

      imports = [
        inputs.copyparty.nixosModules.default
        nixos.common
        nixos.atuin
        nixos.zfs
        nixos.systemd-networking
      ];

      antob = {

        monitoring = {
          emailFrom = "home@antob.se";
          emailTo = "tob@antob.se";
        };
      };

      nixpkgs.config = {
        allowUnfree = true;
      };

      services = {
        fstrim.enable = mkDefault true;

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

        caddy.antobProxies."pihole-web" = {
          hostName = "192.168.1.4";
          port = 80;
        };
      };

      # Ensure folders in ZFS pool
      systemd.tmpfiles.rules = [
        "d /mnt/tank/services 0755 root root -"
      ];

      # Enable IP forwarding
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };

      # Sops secrets
      sops = {
        defaultSopsFile = ./secrets.yaml;
      };

      environment.systemPackages = with pkgs; [
        libva # For hardware transcoding
        mosquitto
      ];

      system.stateVersion = "22.11";
    };
}
