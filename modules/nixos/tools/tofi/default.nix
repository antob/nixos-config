{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.tools.tofi;
in {
  options.antob.tools.tofi = with types; {
    enable = mkEnableOption "Whether or not to install and configure tofi.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.file = { ".config/tofi/config".source = ./config; };
    };
  };
}
