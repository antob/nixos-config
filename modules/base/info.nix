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

    {
      options.antob.info = {
        laptop = mkBoolOpt false "The system is a laptop.";
      };
    };
}
