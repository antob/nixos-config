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
    minimal = mkBoolOpt false "Whether or not to only do minimal install.";
  };

  imports = [
    ./plugins
  ];

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      imports = [
        ./options.nix
        ./utils.nix
        ./colorscheme.nix
        ./autocmd.nix
        ./filetypes.nix
        ./keymaps.nix
      ]
      ++ lib.optionals (!cfg.minimal) [
        ./syntax
        ./diagnostic.nix
        ./lsp
      ];
      programs.neovim = {
        enable = true;
        vimAlias = true;
        withRuby = !cfg.minimal;
        withPython3 = !cfg.minimal;
      };
    };
  };
}
