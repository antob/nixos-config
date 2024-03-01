{ lib, ... }:

with lib.antob;
{
  services = {
    syncthing = {
      enable = true;
      dataDir = "/mnt/tank/syncthing";
      openDefaultPorts = true;
      overrideDevices = false;
      overrideFolders = false;
      # settings = {
      #   devices = {
      #     "laptob-fw" = { id = "6LOVNRB-YSW65OL-RRN4GXI-LMF5BD3-JIY3UBU-DDTR7T3-35VTT3Z-2I2U4AM"; };
      #   };
      #   folders = {
      #     "Documents" = {
      #       path = "/mnt/tank/syncthing/Documents";
      #       devices = [ "laptob-fw" ];
      #     };
      #     "Projects" = {
      #       path = "/mnt/tank/syncthing/Projects";
      #       devices = [ "laptob-fw" ];
      #     };
      #     "Pictures" = {
      #       path = "/mnt/tank/syncthing/Pictures";
      #       devices = [ "laptob-fw" ];
      #     };
      #   };
      # };
    };
  };

  fileSystems = {
    "/mnt/tank/syncthing" = {
      device = "zpool/syncthing";
      fsType = "zfs";
    };
  };

  system.activationScripts.syncthing-chown.text = ''
    chown syncthing:syncthing /mnt/tank/syncthing
  '';

  services.nginx.virtualHosts = {
    "syncthing.lan" = {
      serverAliases = [ "syncthing" ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:8384";
        extraConfig = ''
          proxy_buffering off;
          proxy_headers_hash_max_size 512;
          proxy_headers_hash_bucket_size 128; 
        '';
      };
    };
  };

  # Syncthing ports: 8384 for remote access to GUI
  networking.firewall.allowedTCPPorts = [ 8384 ];
}
