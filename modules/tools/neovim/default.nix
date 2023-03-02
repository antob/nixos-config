{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.tools.neovim;
in
{
  options.antob.tools.neovim = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable neovim.";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
    };
  };
}


