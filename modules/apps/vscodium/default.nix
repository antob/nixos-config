{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.apps.vscodium;
in {
  options.antob.apps.vscodium = with types; {
    enable = mkEnableOption "Enable VSCodium";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ vscodium ];
      shellAliases = { code = "codium"; };
    };
    antob.persistence.home.directories = [ ".config/VSCodium" ];
  };
}
