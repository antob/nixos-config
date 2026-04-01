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
      -- require("mini.pairs").setup({})
      require("mini.jump").setup({})
      require("mini.cursorword").setup({})
      require("mini.icons").setup({})
      require("mini.move").setup({})
      require("mini.bracketed").setup({
        comment = { suffix = "", options = {} },
        file = { suffix = "", options = {} },
        treesitter = { suffix = "", options = {} },
      })
      require("mini.basics").setup({
        mappings = {
          option_toggle_prefix = [[\]],
          windows = true,
        },
      })
      require("mini.bufremove").setup({})

      local hipatterns = require("mini.hipatterns")
      hipatterns.setup({
        highlighters = {
          -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
          fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
          hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
          todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
          note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
    '';
  };
}
