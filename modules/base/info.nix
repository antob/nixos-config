{ config, ... }:
let
  inherit (config.flake.lib) mkBoolOpt;
in
{
  flake.modules.nixos.base =
    {
      lib,
      ...
    }:

    with lib;
    {
      options.antob.info = with types; {
        laptop = mkBoolOpt false "The system is a laptop.";
      };
    };
}
