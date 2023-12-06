{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.apps.vscodium;
in {
  options.antob.apps.vscodium = with types; {
    enable = mkEnableOption "Enable VSCodium";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ vscodium ];
      shellAliases = { code = "LD_LIBRARY_PATH=$(nix build --print-out-paths --no-link nixpkgs#libGL)/lib codium"; };
    };
    antob.persistence.home.directories = [ ".config/VSCodium" ".vscode-oss" ];
  };
}
