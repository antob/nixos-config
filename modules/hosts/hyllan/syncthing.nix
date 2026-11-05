{
  flake.modules.nixos.hyllan =
    _:

    let
      subdomain = "syncthing";
      port = 8384;
      dataDir = "/mnt/tank/services/syncthing";
    in
    {
      services = {
        syncthing = {
          enable = true;
          inherit dataDir;
          openDefaultPorts = true;
          overrideDevices = false;
          overrideFolders = false;
          guiAddress = "127.0.0.1:${toString port}";
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
        inherit port;
        # Syncthing rejects non-localhost Host headers when the GUI listens on localhost
        extraConfig = ''
          header_up Host {upstream_hostport}
        '';
      };
    };
}
