{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  flake.modules.nixos.base =
    { lib, ... }:

    with lib;
    {
      options.antob.monitoring = with types; {
        emailFrom = mkOpt str "home@antob.se" "Monitoring email from address.";
        emailTo = mkOpt str "tob@antob.se" "Monitoring email to address.";
      };
    };
}
