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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      llama-cpp-vulkan
      vulkan-tools
    ];

    antob.persistence = {
      home.directories = [ ".cache/llama.cpp" ];
    };
  };
}
