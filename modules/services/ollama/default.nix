{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.services.ollama;
in
{
  options.antob.services.ollama = with types; {
    enable = mkEnableOption "Whether or not to enable Ollama.";
    host = mkOpt str "127.0.0.1" "The host address which the ollama server HTTP interface listens to.";
    port = mkOpt int 11434 "Which port the ollama server listens to.";
    openFirewall = mkBoolOpt false "Whether or not to open the port in the firewall.";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      host = cfg.host;
      port = cfg.port;
      environmentVariables = {
        OLLAMA_ORIGINS = "*";
        OLLAMA_KEEP_ALIVE = "1h";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "f16";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_CONTEXT_LENGTH = "65536";
        OLLAMA_MAX_LOADED_MODELS = "2";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    environment.sessionVariables.OLLAMA_HOST = cfg.host;

    antob.persistence.directories = [ "/var/lib/private/ollama" ];
  };
}
