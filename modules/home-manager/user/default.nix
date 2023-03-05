{ options, config, pkgs, lib, mkOpt, ... }:

with lib;

let
  mkOpt = type: default: description:
    mkOption { inherit type default description; };

  cfg = config.host.user;

in {
  options.host.user = with types; {
    name = mkOpt str "short" "The name to use for the user account.";
    fullName = mkOpt str "Tobias Lindholm" "The full name of the user.";
    email = mkOpt str "tobias.lindholm@antob.se" "The email of the user.";
  };

  config = {
    home = {
      username = cfg.name;
      homeDirectory = "/home/${cfg.name}";

      file = { ".face".source = ./profile.png; };
    };
  };
}
