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
    ../../modules
  ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    desktop = {
      mango = enabled;
      addons = {
        swayidle.lockScreen = false; # Until swaylock is configured..
        keyring = enabled;
      };
    };

    virtualisation.virt-manager = enabled;

    tools = {
      fhs = enabled;
      atuin = enabled;
      # easyeffects = {
      #   enable = true;
      #   preset = "fw13";
      # };
    };

    services.tailscale = {
      enable = true;
      keyfile = secrets.tailscale_auth_key.path;
    };

    hardware = {
      systemd-networking = {
        enable = true;
        hostName = "laptob-fw";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "6278643e";
      };
      fingerprint = enabled;
      bluetooth = enabled;
      zsa-voyager = enabled;
      yubikey = enabled;
      ledger = enabled;
    };

    system = {
      info.laptop = true;
      console.setFont = mkForce false;
    };

    persistence = {
      enable = true;
      path = "/nix/persist";
      directories = [
        "/var/lib/powertop"
        "/var/lib/chrony"
      ];
      home.directories = [
        ".config/rustdesk"
        ".config/vice"
        ".RetroDebugger"
        ".C64Debugger"
        ".nuget"
        ".microsoft"
        ".dotnet"
        ".aws"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    powertop
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
    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend";
    };
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

  # Power optimizer daemons. Choose one.
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  system.stateVersion = "22.11";
}
