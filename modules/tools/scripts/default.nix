{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.scripts;
  cp = pkgs.callPackage;
in
{
  options.antob.tools.scripts = with types; {
    enable = mkEnableOption "Whether or not to enable custom scripts.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (cp ./bb.nix { })
      (cp ./catbin.nix { })
      (cp ./getsong.nix { })
      (cp ./sfx.nix { })
      (cp ./timer.nix { })
    ];
  };
}
