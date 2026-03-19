{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      mini-nvim
    ];

    initLua = /* lua */ ''
      require("mini.misc").setup({})
      require("mini.surround").setup({})
      require("mini.pairs").setup({})
      require("mini.jump").setup({})
      require("mini.cursorword").setup({})
      require("mini.icons").setup({})
      require("mini.move").setup({})
      require("mini.bracketed").setup({
        comment = { suffix = "", options = {} },
        file = { suffix = "", options = {} },
      })
      require("mini.basics").setup({
        mappings = {
          option_toggle_prefix = [[\]],
          windows = true,
        },
      })
      require("mini.bufremove").setup({})
    '';
  };
}
