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
    nur.modules.nixos.default
    ./hardware.nix
  ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    apps = {
      thunderbird = enabled;
      lm-studio = enabled;
    };

    desktop = {
      niri = enabled;
      addons = {
        swayidle.lockScreen = false;
        keyring = enabled;
      };
    };

    virtualisation = {
      virt-manager = enabled;

      docker.enable = false;
      docker.storageDriver = "btrfs";

      podman.enable = true;
      podman.storageDriver = "btrfs";
    };

    tools = {
      fhs = enabled;
      atuin = enabled;
      alacritty.fontSize = 13;
    };

    services.ollama = {
      enable = true;
      host = "100.64.0.8";
      openFirewall = true;
    };

    cli-apps.llama-cpp = enabled;

    services.tailscale = {
      enable = true;
      keyfile = secrets.tailscale_auth_key.path;
    };

    hardware = {
      bluetooth = enabled;
      zsa-voyager = enabled;
      yubikey = enabled;
      ledger = enabled;
    };

    system.console.setFont = mkForce false;
    services.avahi.enable = mkForce false;

    persistence = {
      enable = true;
      directories = [
        "/var/lib/chrony"
        "/var/lib/iwd"
      ];
      home.directories = [
        ".config/rustdesk"
        ".config/vice"
        ".RetroDebugger"
        ".C64Debugger"
        # ".nuget"
        # ".microsoft"
        # ".dotnet"
        ".aws"
      ];
    };

    # Use custom setup for networking
    hardware.networking.enable = mkForce false;
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    amdgpu_top
    radeontop
    glxinfo
    acpi
    s-tui
    just
    nixos-anywhere
    sops
    quickemu
    nfs-utils # Needed for mounting NFS shares
    rustdesk-flutter
    iio-sensor-proxy # To enable automatic brightness in Gnome
    calibre
  ];

  services = {
    fwupd.enable = true;
    chrony.enable = true;
    resolved.enable = true;
  };

  # Networking and firewall
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
    };
    nftables.enable = true;
    useDHCP = false;
    usePredictableInterfaceNames = false;

    hostName = "desktob";

    # Derived from `head -c 8 /etc/machine-id`
    hostId = "672fb36e";

    # Wireless config
    wireless.iwd = {
      enable = true;
      settings = {
        Settings = {
          AutoConnect = true;
        };
      };
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        matchConfig.Name = "eth0";
        networkConfig.DHCP = "yes";
        linkConfig.RequiredForOnline = "no";
      };
      "10-wireless" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "yes";
          IgnoreCarrierLoss = "3s";
        };
      };
    };
  };

  # Do not wait for network connectivity (will timeout on nixos-rebuild)
  systemd.services.systemd-networkd-wait-online.enable = mkForce false;

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      configurationLimit = 10;
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

  # To be able to access ESP32 devices through the serial port
  antob.user.extraGroups = [ "dialout" ];

  # NFS shares
  services.rpcbind.enable = true;
  systemd.mounts = [
    {
      type = "nfs4";
      mountConfig = {
        Options = "noatime";
      };
      what = "hyllan.lan:/mnt/tank/share/public";
      where = "/mnt/share/public";
    }
    {
      type = "nfs4";
      mountConfig = {
        Options = "noatime";
      };
      what = "hyllan.lan:/mnt/tank/share/private";
      where = "/mnt/share/private";
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/mnt/share/public";
    }
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/mnt/share/private";
    }
  ];

  system.stateVersion = "22.11";
}
