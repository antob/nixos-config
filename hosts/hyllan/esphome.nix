{
  pkgs,
  ...
}:

let
  subdomain = "esphome";
  port = 6052;
  dataDir = "/mnt/tank/services/esphome";
in
{
  users.users.esphome = {
    isSystemUser = true;
    home = dataDir;
    group = "esphome";
  };
  users.groups.esphome = { };

  systemd.services.esphome = {
    description = "ESPHome Device Builder dashboard";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    # Keep esphome/esptool on PATH for child firmware build processes.
    path = [ pkgs.esphome-device-builder ];
    environment = {
      PLATFORMIO_CORE_DIR = "${dataDir}/.platformio";
      HOME = dataDir;
    };
    serviceConfig = {
      ExecStart = "${pkgs.esphome-device-builder}/bin/esphome-device-builder --host 127.0.0.1 --port ${toString port} ${dataDir}";
      User = "esphome";
      Group = "esphome";
      WorkingDirectory = dataDir;
      StateDirectory = "esphome";
      StateDirectoryMode = "0750";
      Restart = "on-failure";
      ReadWritePaths = [ dataDir ];
      ExecPaths = [ dataDir ];

      # Hardening, modelled on the (now obsolete) upstream esphome module.
      # PlatformIO needs a writable HOME, chroot/@mount and network to build.
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      DevicePolicy = "closed";
      DeviceAllow = [
        "char-ttyS rw"
        "char-ttyUSB rw"
      ];
      SupplementaryGroups = [ "dialout" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = false; # breaks bwrap
      ProtectKernelLogs = false; # breaks bwrap
      ProtectKernelModules = true;
      ProtectKernelTunables = false; # breaks bwrap
      ProtectProc = "invisible";
      ProcSubset = "all"; # Using "pid" breaks bwrap
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
        "AF_UNIX"
      ];
      RestrictNamespaces = false; # Required by platformio for chroot
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "@mount" # Required by platformio for chroot
      ];
      UMask = "0077";
    };
  };

  services.caddy.antobProxies."${subdomain}" = {
    hostName = "127.0.0.1";
    port = port;
    extraHandleConfig = ''
      basic_auth {
        admin {$ESPHOME_ADMIN_PASSWORD}
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 esphome esphome -"
  ];

  # mDNS so the dashboard can discover devices by name on the LAN.
  networking.firewall.allowedUDPPorts = [ 5353 ];
}
