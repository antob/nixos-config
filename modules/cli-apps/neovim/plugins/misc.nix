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
    ];

    initLua = /* lua */ ''
      require("nvim-ts-autotag").setup({})
      require("Comment").setup()
    '';
  };
}
