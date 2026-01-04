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
