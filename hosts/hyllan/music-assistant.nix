{ ... }:

let
  subdomain = "music";
  port = 8095;
  dataDir = "/mnt/tank/services/mass";
  localMusicDir = "/mnt/tank/share/public/Music";
in
{
  virtualisation.oci-containers.containers = {
    mass = {
      image = "ghcr.io/music-assistant/server:2.8.0b8";
      autoStart = true;
      extraOptions = [
        "--network=host"
      ];
      capabilities = {
        SYS_ADMIN = true;
        DAC_READ_SEARCH = true;
      };
      environment = {
        TZ = "Europe/Stockholm";
      };
      volumes = [
        "${dataDir}:/data"
        "${localMusicDir}:/mnt/Music"
      ];
    };
  };

  services.caddy.antobProxies."${subdomain}" = {
    hostName = "127.0.0.1";
    port = port;
  };

  virtualisation.oci-containers.containers = {
    ytdlp-pot-provider = {
      image = "docker.io/brainicism/bgutil-ytdlp-pot-provider:latest";
      autoStart = true;
      extraOptions = [
        "--network=host"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    8097 # Port to stream audio to players
    4416 # bgutil-ytdlp-pot-provider
  ];
}
