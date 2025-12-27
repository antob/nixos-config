{
  config,
  lib,
  inputs,
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
    nixpkgs.overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];

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
      ];

      programs.neovim = {
        enable = true;
        vimAlias = true;
      };
    };
  };
}
