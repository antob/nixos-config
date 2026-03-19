{ ... }:

let
  subdomain = "chat";
  port = 11435;
  dataDir = "/mnt/tank/services/open-webui";
in
{
  services = {
    open-webui = {
      enable = true;
      port = port;
      environment = {
        SCARF_NO_ANALYTICS = "True";
        DO_NOT_TRACK = "True";
        ANONYMIZED_TELEMETRY = "False";
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "False";
        CHAT_STREAM_RESPONSE_CHUNK_MAX_BUFFER_SIZE = "20971520"; # 20 MiB
        REPLACE_IMAGE_URLS_IN_CHAT_RESPONSE = "True";
      };
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "http://127.0.0.1";
      port = port;
    };
  };

  fileSystems = {
    "/var/lib/private/open-webui" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 nobody nobody -"
  ];
}
