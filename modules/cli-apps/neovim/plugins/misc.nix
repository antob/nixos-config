{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      nvim-autopairs
      vim-tmux-navigator
    ];

    extraLuaConfig = /* lua */ ''
      require("nvim-autopairs").setup({})
    '';
  };
}
