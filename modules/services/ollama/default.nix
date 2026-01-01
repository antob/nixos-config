# Add printer with: `$ lpadmin -p HP -E -v "ipp://192.168.1.120/ipp/print" -m everywhere`
{
  config,
  pkgs,
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
      package = pkgs.ollama-vulkan;

      host = cfg.host;
      port = cfg.port;
      environmentVariables = {
        OLLAMA_ORIGINS = "*";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    environment.sessionVariables.OLLAMA_HOST = cfg.host;

    antob.persistence = {
      directories = [ "/var/lib/private/ollama" ];
    };
  };
}
