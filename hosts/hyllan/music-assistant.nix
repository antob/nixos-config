{ ... }:

let
  subdomain = "music";
  port = 8095;
  dataDir = "/mnt/tank/services/music-assistant";
in
{
  antob.services = {
    music-assistant = {
      enable = true;
      providers = [
        # "airplay"
        "dlna"
        "filesystem_local"
        "sonos"
        "soundcloud"
        "spotify"
        "ytmusic"
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

  fileSystems = {
    "/var/lib/private/music-assistant" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 nobody nobody -"
  ];
}
