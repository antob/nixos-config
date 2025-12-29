{
  pkgs,
  lib,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      vague-nvim
      catppuccin-nvim
    ];

    extraLuaConfig = lib.mkOrder 210 /* lua */ ''
      -- require("vague").setup({
      --   transparent = true,
      --   on_highlights = function(hl, c)
      --     hl.LspReferenceRead = { gui = "bold", blend = 80 }
      --     hl.LspReferenceText = { gui = "bold", blend = 80 }
      --     hl.LspReferenceWrite = { gui = "bold", blend = 80 }
      --   end,
      -- })

      -- vim.cmd("colorscheme vague")

      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        custom_highlights = function(colors)
          return {
            LspReferenceRead = { bg = colors.none, blend = 80, style = { "bold" } },
            LspReferenceText = { bg = colors.none, blend = 80, style = { "bold" } },
            LspReferenceWrite = { bg = colors.none, blend = 80, style = { "bold" } },
          }
        end,
      })

      vim.cmd("colorscheme catppuccin-mocha")
    '';
  };
}
