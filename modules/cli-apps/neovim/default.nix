{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.neovim;
in
{
  options.antob.cli-apps.neovim = with types; {
    enable = mkEnableOption "Whether or not to enable neovim";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      imports = [
        ./options.nix
        ./utils.nix
        ./colorscheme.nix
        ./diagnostic.nix
        ./autocmd.nix
        ./filetypes.nix
        ./keymaps.nix
        ./lsp
        ./plugins
        ./syntax
      ];

      programs.neovim = {
        enable = true;
        vimAlias = true;
        withRuby = true;
        withPython3 = true;
      };
    };
  };
}
