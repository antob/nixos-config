{ options, config, pkgs, lib, ... }:

with lib;

let
  mkOpt = type: default: description:
    mkOption { inherit type default description; };
  mkBoolOpt = mkOpt types.bool;
  cfg = config.host.tools.neovim;

in {
  options.host.tools.neovim = with types; {
    enable = mkBoolOpt false "Whether or not to enable neovim.";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
    };
  };
}
