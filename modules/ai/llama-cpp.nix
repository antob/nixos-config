{ config, ... }:
let
  inherit (config.flake.lib) mkOpt mkBoolOpt;
in
{
  flake.modules.nixos.llama-cpp =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.llama-cpp;
    in
    {
      options.antob.llama-cpp = with types; {
        package = mkOpt package pkgs.llama-cpp "The llama-cpp package to use.";
        runAsService = mkBoolOpt false "Run llama.cpp as a systemd service.";
        loadOnStartup = mkOpt (listOf str) [ ] "Models to be loaded on startup.";
        host = mkOpt str "127.0.0.1" "Address the llama-server service listens on.";
        port = mkOpt port 8080 "Port the llama-server service listens on.";
        openFirewallInterfaces = mkOpt (listOf str) [ ] "Interface names on which to open the port.";
        apiKeyFile =
          mkOpt (nullOr str) null
            "File with the API key clients must send. Passed to the service as a credential.";
      };

      config = {
        environment.systemPackages = [
          cfg.package
        ];

        services.llama-cpp = mkIf cfg.runAsService {
          enable = true;
          settings = {
            inherit (cfg) host port;
            models-max = 2;
            models-preset =
              let
                loadOnStartup =
                  name: lib.optionalString (lib.elem name cfg.loadOnStartup) "load-on-startup = true\n";
                model = name: body: ''
                  [${name}]
                  ${body}
                  ${loadOnStartup name}
                '';
              in
              pkgs.writeText "preset.ini" (
                concatStringsSep "\n" [
                  (model "qwen3.6-35B" /* ini */ ''
                    hf = unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL
                    ctx-size = 262144
                    temp = 0.6
                    top-p = 0.95
                    top-k = 20
                    min-p = 0.00
                    flash-attn = on
                    ubatch-size = 2048
                    batch-size = 2048
                    image-min-tokens = 1120
                    image-max-tokens = 1120
                  '')

                  (model "zeroclaw" /* ini */ ''
                    hf = unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL
                    ctx-size = 32768
                    parallel = 1
                    n-predict = 2048
                    temp = 0.7
                    top-p = 0.8
                    top-k = 20
                    min-p = 0.00
                    presence-penalty = 1.5
                    flash-attn = on
                    reasoning = off
                    no-mmproj = true
                    chat-template-file = ${./_files/zeroclaw-qwen3.6.jinja}
                  '')

                  (model "gemma4-26B" /* ini */ ''
                    hf = unsloth/gemma-4-26B-A4B-it-GGUF:UD-Q4_K_XL
                    ctx-size = 262144
                    temp = 1
                    top-p = 0.95
                    top-k = 64
                    reasoning = on
                  '')

                  (model "ornith-1.0-35B" /* ini */ ''
                    ctx-size = 262144
                    temp = 0.6
                    top-p = 0.95
                    top-k = 20
                    reasoning = on
                  '')

                  (model "qwen2.5-coder-7B" /* ini */ ''
                    hf = ggml-org/Qwen2.5-Coder-7B-Q8_0-GGUF
                  '')

                  (model "qwen2.5-coder-3B" /* ini */ ''
                    hf = ggml-org/Qwen2.5-Coder-3B-Q8_0-GGUF
                  '')
                ]
              );
          }
          // optionalAttrs (cfg.apiKeyFile != null) {
            api-key-file = "/run/credentials/llama-cpp.service/api-key";
          };
        };

        # The service runs as a DynamicUser, so it cannot read the root-owned secret directly.
        systemd.services.llama-cpp.serviceConfig.LoadCredential = mkIf (
          cfg.runAsService && cfg.apiKeyFile != null
        ) [ "api-key:${cfg.apiKeyFile}" ];

        networking.firewall.interfaces = mkIf (cfg.runAsService && cfg.openFirewallInterfaces != [ ]) (
          listToAttrs (
            map (iface: {
              name = iface;
              value.allowedTCPPorts = [ cfg.port ];
            }) cfg.openFirewallInterfaces
          )
        );

        # Model downloads (LLAMA_CACHE) would otherwise be repeated on every boot.
        antob.persistence.directories = mkIf cfg.runAsService [ "/var/cache/private/llama-cpp" ];

        antob.persistence.home.directories = [
          ".cache/llama.cpp"
          ".cache/huggingface"
        ];
      };
    };

}
