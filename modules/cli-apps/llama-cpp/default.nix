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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    antob.persistence = {
      home.directories = [
        ".cache/llama.cpp"
        ".cache/huggingface"
      ];
    };
  };
}
