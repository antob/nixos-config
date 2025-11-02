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

    services = {
      ollama = {
        enable = true;
        host = "100.64.0.8";
        openFirewall = true;
      };
      tailscale = {
        enable = true;
        keyfile = secrets.tailscale_auth_key.path;
      };
    };

    cli-apps.llama-cpp = enabled;

    hardware = {
      systemd-networking = {
        enable = true;
        hostName = "desktob";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "672fb36e";
      };
      bluetooth = enabled;
      zsa-voyager = enabled;
      yubikey = enabled;
      ledger = enabled;
    };

    system.console.setFont = mkForce false;

    persistence = {
      enable = true;
      directories = [
        "/var/lib/chrony"
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
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    amdgpu_top
    radeontop
    mesa-demos
    acpi
    s-tui
    quickemu
    nfs-utils # Needed for mounting NFS shares
    rustdesk-flutter
    iio-sensor-proxy # To enable automatic brightness in Gnome
    calibre
  ];

  services = {
    fwupd.enable = true;
    chrony.enable = true;
  };

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
