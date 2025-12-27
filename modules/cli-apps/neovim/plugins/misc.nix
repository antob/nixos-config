{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      plenary-nvim
      nvim-autopairs
      vim-tmux-navigator
      lazygit-nvim
    ];

    extraLuaConfig = /* lua */ ''
      require("nvim-autopairs").setup({})
    '';
  };
}
