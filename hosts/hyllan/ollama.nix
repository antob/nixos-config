{ pkgs, ... }:

let
  subdomain = "ollama";
  port = 11434;
  dataDir = "/mnt/tank/services/ollama";
in
{
  services = {
    ollama = {
      enable = true;
      acceleration = "cuda";

      package = pkgs.ollama.override {
        cudaPackages = pkgs.cudaPackages_12_0;
      };

      loadModels = [
        "mistral:latest"
        "qwen2.5-coder:1.5b-base"
        "nomic-embed-text:latest"
      ];

      environmentVariables = {
        OLLAMA_ORIGINS = "*";
      };
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "http://127.0.0.1";
      port = port;
      extraConfig = ''
        header_up Host 127.0.0.1
      '';
    };
  };

  fileSystems = {
    "/var/lib/private/ollama" = {
      device = dataDir;
      options = [ "bind" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 nobody nobody -"
  ];
}
