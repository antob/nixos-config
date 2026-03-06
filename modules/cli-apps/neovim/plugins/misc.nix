{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-ts-autotag
      vim-eunuch
    ];

    initLua = /* lua */ ''
      require("nvim-ts-autotag").setup({})
    '';
  };
}
