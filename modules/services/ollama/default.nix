{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.services.ollama;
in
{
  options.antob.services.ollama = with types; {
    enable = mkEnableOption "Whether or not to enable Ollama.";
    package = mkOpt package pkgs.ollama "The ollama package to use.";
    host = mkOpt str "127.0.0.1" "The host address which the ollama server HTTP interface listens to.";
    port = mkOpt int 11434 "Which port the ollama server listens to.";
    openFirewall = mkBoolOpt false "Whether or not to open the port in the firewall.";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = cfg.package;
      host = cfg.host;
      port = cfg.port;
      environmentVariables = {
        OLLAMA_ORIGINS = "*";
        OLLAMA_KEEP_ALIVE = "1h";
        OLLAMA_IGPU_ENABLE = "1"; # For Vulkan backend, enable iGPU support.
        OLLAMA_NUM_PARALLEL = "2";
        OLLAMA_MAX_LOADED_MODELS = "2";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    environment.sessionVariables.OLLAMA_HOST = cfg.host;

    antob.persistence.directories = [ "/var/lib/private/ollama" ];

    antob.home.extraOptions.programs.zsh.initContent = /* bash */ ''
      # Function to fetch and return model names from 'ollama list'
      _fetch_ollama_models() {
          local -a models
          local output="$(ollama list 2>/dev/null | sed 's/:/\\:/g')"  # Escape semicolons for zsh
          if [[ -z "$output" ]]; then
              _message "no models available or 'ollama list' failed"
              return 1
          fi
          models=("''${(@f)$(echo "$output" | awk 'NR>1 {print $1}')}")
          if [[ ''${#models} -eq 0 ]]; then
              _message "no models found"
              return 1
          fi
          _describe 'model names' models
      }

      # Function to fetch and return model names from 'ollama ps'
      _fetch_ollama_running_models() {
          local -a models
          local output="$(ollama ps 2>/dev/null | sed 's/:/\\:/g')"  # Escape semicolons for zsh
          if [[ -z "$output" ]]; then
              _message "no models running or 'ollama ps' failed"
              return 1
          fi
          models=("''${(@f)$(echo "$output" | awk 'NR>1 {print $1}')}")
          if [[ ''${#models} -eq 0 ]]; then
              _message "no models found"
              return 1
          fi
          _describe 'model names' models
      }

      # Main completion function
      _ollama() {
          local -a commands

          _arguments -C \
              '1: :->command' \
              '*:: :->args'

          case $state in
              command)
                  commands=(
                      'show:Show information for a model'
                      'run:Run a model'
                      'stop:Stop a running model'
                      'pull:Pull a model from a registry'
                      'push:Push a model to a registry'
                      'list:List models'
                      'rm:Remove a model'
                  )
                  _describe -t commands 'ollama command' commands
              ;;
              args)
                  case $words[1] in
                      show)
                          _arguments \
                              '*::model:->model'
                          if [[ $state == model ]]; then
                              _fetch_ollama_models
                          fi
                      ;;
                      run)
                          _arguments \
                              '*::model and prompt:->model_and_prompt'
                          if [[ $state == model_and_prompt ]]; then
                              _fetch_ollama_models
                              _message "enter prompt"
                          fi
                      ;;
                      stop)
                          _arguments \
                              '*::model:->model'
                          if [[ $state == model ]]; then
                              _fetch_ollama_running_models
                          fi
                      ;;
                      pull|push)
                          _arguments \
                              '*::model:->model'
                          if [[ $state == model ]]; then
                              _fetch_ollama_models
                          fi
                      ;;
                      list)
                          _message "no additional arguments for list"
                      ;;
                      rm)
                          _arguments \
                              '*::models:->models'
                          if [[ $state == models ]]; then
                              _fetch_ollama_models
                          fi
                      ;;
                  esac
              ;;
          esac
      }

      compdef _ollama ollama
    '';
  };
}
