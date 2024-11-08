{
  pkgs,
  lib,
  ...
}:
with lib;
with lib.antob; {
  imports = [
    ./hardware.nix
  ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    desktop.gnome = enabled;

    virtualisation.virt-manager = enabled;

    hardware = {
      fingerprint = enabled;
      bluetooth = enabled;
      zsa-voyager = enabled;
      yubikey = enabled;
    };

    system.console.setFont = mkForce false;
  };

  environment.systemPackages = with pkgs; [
    powertop
    vulkan-tools
    amdgpu_top
    radeontop
    glxinfo
    deploy-rs
    sops
    quickemu
    nfs-utils # Needed for mounting NFS shares
  ];

  services = {
    fwupd.enable = true;

    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";
    };

    chrony.enable = true;

    tailscale.enable = true;
  };

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
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/mnt/share/public";
    }
    {
      wantedBy = ["multi-user.target"];
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
