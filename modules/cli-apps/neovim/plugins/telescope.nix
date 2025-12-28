{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      telescope-nvim
      telescope-fzf-native-nvim
    ];

    extraLuaConfig = /* lua */ ''
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          preview = { treesitter = false },
          color_devicons = true,
          prompt_prefix = "  ",
          selection_caret = " ",
          entry_prefix = " ",
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          results_title = false,
          dynamic_preview_title = true,
          file_ignore_patterns = {
            "^.git/",
            "^node_modules/",
            "^.devenv/",
            "^.direnv/",
          },
          borderchars = {
            "", -- top
            "", -- right
            "", -- bottom
            "", -- left
            "", -- top-left
            "", -- top-right
            "", -- bottom-right
            "", -- bottom-left
          },
          path_displays = { "smart" },
          layout_config = {
            height = 100,
            width = 400,
            prompt_position = "top",
            preview_cutoff = 40,
          },
          mappings = {
            i = {
              ["<Esc>"] = "close",
              ["<C-Down>"] = "cycle_history_next",
              ["<C-Up>"] = "cycle_history_prev",
            },
          },
        }
      })
      telescope.load_extension("fzf")

      -- open filepicker on start
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argv(0) == "" then
            vim.defer_fn(function()
              require('telescope.builtin').oldfiles()
            end, 10)
          end
        end,
      })
    '';
  };
}
