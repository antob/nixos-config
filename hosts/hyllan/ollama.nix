{ pkgs, ... }:

let
  subdomain = "ollama";
  port = 11434;
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
        # CUDA_VISIBLE_DEVICES = "0";
        # NVIDIA_VISIBLE_DEVICES = "all";
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
}
