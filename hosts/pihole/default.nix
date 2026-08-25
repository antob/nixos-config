{
  lib,
  pkgs,
  config,
  ...
}:

with lib;
let
  secrets = config.sops.secrets;
  piholeFtl = config.services.pihole-ftl;
in
{
  imports = [
    ./hardware.nix
  ];

  antob = {
    features.rpi = enabled;
    hardware.systemd-networking = {
      enable = true;
      hostName = "pihole";
      enableWireless = false;
      enableVpn = false;
      # Derived from `head -c 8 /etc/machine-id`
      hostId = "78b3aca6";
      staticIp = {
        enable = true;
        address = "192.168.1.4/24";
        dns = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        gateway = "192.168.1.1";
      };
    };
    services.wireguard = {
      enable = true;
      address = "10.64.1.4/24";
      privateKeyFile = secrets.wg0_private_key.path;
    };
  };

  #
  # Services
  #
  services = {
    # I'm not actually using the dnsmasq service. Pi-hole provides
    # it's own dnsmasq. I'm using Nix' ability to manage the
    # dnsmasq-style configuration file that Pi-hole utilizes.
    dnsmasq = {
      enable = false;
      settings = {
        address = [
          "/hyllan.lan/192.168.1.2 # Wildcard DNS for hyllan.lan"
          "/antob.net/10.64.1.2 # Wildcard DNS for antob.net"
        ];
        dhcp-name-match = [
          "set:hostname-ignore,wpad"
          "set:hostname-ignore,localhost"
        ];
        # Set DHCP option 6 to the DNS server your nodes should use.
        dhcp-option = [
          "vendor:MSFT,2,1i"
          "6,192.168.1.4"
        ];
        domain = [
          "lan,192.168.1.0/24,local"
        ];
      };
    };

    pihole-ftl = {
      enable = true;
      lists = [
        {
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          type = "block";
          enabled = true;
          description = "Steven Black's HOSTS";
        }
      ];
      openFirewallDNS = true;
      openFirewallDHCP = true;
      openFirewallWebserver = true;
      queryLogDeleter.enable = true;
      settings = {
        dhcp = {
          active = true;
          start = "192.168.1.100";
          end = "192.168.1.199";
          router = "192.168.1.1";
          leaseTime = "24h";
          ipv6 = false;
          rapidCommit = true;
          resolver = {
            resolveIPv6 = false;
          };
        };
        misc.readOnly = false;
        dns = {
          cnameRecords = [
            "esphome.lan,hyllan.lan"
            "syncthing.lan,hyllan.lan"
            "zigbee.lan,hyllan.lan"
          ];
          domain = "lan";
          domainNeeded = true;
          expandHosts = true;
          interface = "eth0";
          hosts = [
            "10.64.1.6      desktob.antob.net"
            "10.64.1.2      hyllan.antob.net"
            "192.168.1.2    hyllan.lan"
            "10.64.1.8      iphone.antob.net"
            "10.64.1.7      laptob-fw.antob.net"
            "10.64.1.4      pihole.antob.net"
            "192.168.1.4    pihole.lan"
            "10.64.1.3      pikvm.antob.net"
            "192.168.1.3    pikvm.lan"
            "10.64.1.5      wiggum.antob.net"
          ];
          upstreams = [
            "1.1.1.1"
            "1.0.0.1"
          ];
          listeningMode = "ALL";
        };
        # Let's not use Pi-hole time service. My home router provides clock.
        ntp = {
          ipv4.active = false;
          ipv6.active = false;
          sync.active = false;
        };
        webserver = {
          api = {
            # To manage the web login:
            # 1) Temporarily set misc.readOnly to false in
            #    configuration.nix and switch to it.
            # 2) Manually set a password:
            #    Pi-hole web console > Settings > All settings >
            #    Webserver and API > webserver.api.password > Value: ******
            # 3) Read the generated hash:
            #    sudo pihole-FTL --config webserver.api.pwhash
            pwhash = "$BALLOON-SHA256$v=1$s=1024,t=32$j4WaaINR5GqCr8KRDNR0jg==$u9Ru8poRlK0Ze47XiWMnYrMeGfUAzMhJ7nsdjK7sfWk=";
          };
          session = {
            timeout = 43200; # 12h
          };
        };
      };
      useDnsmasqConfig = true;
    };

    pihole-web = {
      enable = true;
      ports = [ 80 ];
    };

    resolved = {
      settings = {
        Resolve = {
          DNSStubListener = false;
          MulticastDNS = false;
        };
      };
    };
  };

  # Workaround for an upstream nixpkgs bug: the log-deleter service inlines
  # the DELETE SQL into the unit's ExecStart, where systemd expands the `%s`
  # specifier (the pihole user's shell, /run/current-system/sw/bin/bash) and
  # strips the SQL's single quotes, producing invalid SQL. Point the service at
  # a generated script file instead, where neither `%` nor quotes are mangled.
  systemd.services.pihole-ftl-log-deleter = mkIf piholeFtl.queryLogDeleter.enable {
    serviceConfig.ExecStart = mkForce [
      (pkgs.writeShellScript "pihole-ftl-log-deleter" ''
        set -euo pipefail

        database=${piholeFtl.settings.files.database}
        days=${toString piholeFtl.queryLogDeleter.age}

        # Avoid creating an empty database file if it doesn't yet exist
        if [ ! -f "$database" ]; then
          exit 0
        fi

        echo "Deleting query logs older than $days days"
        ${lib.getExe piholeFtl.package} sqlite3 "$database" "DELETE FROM query_storage WHERE timestamp <= CAST(strftime('%s', date('now', '-$days day')) AS INT); select changes() from query_storage limit 1"
      '')
    ];
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      wg0_private_key = {
        owner = "systemd-network";
      };
    };
  };

  system.stateVersion = "21.11";
}
