{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-ts-autotag
      vim-eunuch
      comment-nvim
      kitty-scrollback-nvim
    ];

    initLua = /* lua */ ''
      require("nvim-ts-autotag").setup({})
      require("Comment").setup()
      require("kitty-scrollback").setup({})
    '';
  };
}
