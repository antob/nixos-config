{
  pkgs,
  lib,
  ...
}:
{
  antob.home.extraOptions.programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-ts-autotag
      vim-eunuch
      comment-nvim
    ];

    initLua = lib.mkOrder 200 /* lua */ ''
      require("nvim-ts-autotag").setup({})
      require("Comment").setup()
    '';
  };
}
