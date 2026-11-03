{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.llama-cpp;
in
{
  options.antob.cli-apps.llama-cpp = with types; {
    enable = mkEnableOption "Whether or not to enable llama.cpp.";
    package = mkOpt package pkgs.llama-cpp "The llama-cpp package to use.";
    runAsService = mkBoolOpt false "Run llama.cpp as a systemd service.";
    loadOnStartup = mkOpt (listOf str) [ ] "Models to be loaded on startup.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    services.llama-cpp = mkIf cfg.runAsService {
      enable = true;
      settings = {
        host = "127.0.0.1";
        port = 8080;
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
      };
    };

    antob.persistence.home.directories = [
      ".cache/llama.cpp"
      ".cache/huggingface"
    ];
  };
}
