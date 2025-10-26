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
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "rocm";

      environmentVariables = {
        OLLAMA_ORIGINS = "*";
      };
    };

    environment.systemPackages = with pkgs; [
      rocmPackages.rocm-runtime
      rocmPackages.rocminfo
      ollama-rocm
    ];

    antob.persistence = {
      directories = [ "/var/lib/private/ollama" ];
    };
  };
}
