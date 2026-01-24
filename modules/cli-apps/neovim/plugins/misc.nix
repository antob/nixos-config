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
      nvim-ts-autotag
      vim-eunuch
    ];

    initLua = /* lua */ ''
      require("nvim-autopairs").setup({})
      require("nvim-ts-autotag").setup({})
    '';
  };
}
