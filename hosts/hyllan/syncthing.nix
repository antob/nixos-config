{ ... }:

let
  subdomain = "syncthing";
  port = 8384;
  dataDir = "/mnt/tank/services/syncthing";
in
{
  services = {
    syncthing = {
      enable = true;
      dataDir = dataDir;
      openDefaultPorts = true;
      overrideDevices = false;
      overrideFolders = false;
      guiAddress = "0.0.0.0:${toString port}";
      settings = {
        devices = {
          "laptob-fw" = {
            id = "6LOVNRB-YSW65OL-RRN4GXI-LMF5BD3-JIY3UBU-DDTR7T3-35VTT3Z-2I2U4AM";
          };
        };
        folders = {
          "Documents" = {
            path = "${dataDir}/Documents";
            devices = [ "laptob-fw" ];
          };
          "Projects" = {
            path = "${dataDir}/Projects";
            devices = [ "laptob-fw" ];
          };
          "Pictures" = {
            path = "${dataDir}/Pictures";
            devices = [ "laptob-fw" ];
          };
        };
      };
    };
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/syncthing";
      fsType = "zfs";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 syncthing syncthing -"
  ];

  services.caddy.antobProxies."${subdomain}" = {
    hostName = "127.0.0.1";
    port = port;
  };

  # Syncthing ports: 8384 for remote access to GUI
  networking.firewall.allowedTCPPorts = [ port ];
}
