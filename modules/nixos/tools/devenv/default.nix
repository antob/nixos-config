{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let cfg = config.antob.tools.devenv;
in
{
  options.antob.tools.devenv = with types; {
    enable = mkBoolOpt false "Whether or not to enable devenv.";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      keep-outputs = true;
      keep-derivations = true;
      substituters = [
        "https://devenv.cachix.org/"
      ];
      trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };

    environment.systemPackages = with pkgs; [ cachix devenv ];
  };
}
