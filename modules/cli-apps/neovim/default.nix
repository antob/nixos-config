{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.neovim;
in
{
  options.antob.cli-apps.neovim = with types; {
    enable = mkEnableOption "Whether or not to enable neovim (with neovim).";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      imports = [
        inputs.nixvim.homeManagerModules.nixvim
      ];

      programs.nixvim = {
        enable = true;

        viAlias = true;
        vimAlias = true;
        nixpkgs.config.allowUnfree = true;

        imports = [
          ./colorschemes.nix
          ./options.nix
          ./autocmd.nix
          ./keymaps.nix
          ./lua-config.nix
          ./packages.nix
          ./plugins/plugins.nix
          ./plugins/telescope.nix
          ./plugins/treesitter.nix
          ./plugins/nvim-tree.nix
          ./plugins/lsp.nix
          ./plugins/cmp.nix
          ./plugins/conform.nix
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      universal-ctags
    ];
  };
}
