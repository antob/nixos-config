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

      local builtin = require("telescope.builtin")
      local utils = require("telescope.utils")
      function all_files() builtin.find_files({ no_ignore = true, follow = true, hidden = true }) end
      function relative_files() builtin.find_files({ cwd = utils.buffer_dir() }) end

      -- telescope find
      map("n", "<leader>ff", builtin.find_files, "Find files")
      map("n", "<C-p>", builtin.find_files, "Find files")
      map("n", "<leader>fa", all_files, "Find all files")
      map("n", "<leader>F", relative_files, "Find files relative to buffer")
      map("n", "<leader>fw", builtin.live_grep, "Find words")
      map("n", "<leader>fb", builtin.buffers, "Find buffers")
      map("n", "<leader>fr", builtin.oldfiles, "Find recent files")
      map("n", "<leader>fh", builtin.help_tags, "Find help page")
      map("n", "<leader>fm", builtin.man_pages, "Find man page")
      map("n", "<leader>lr", builtin.lsp_references)
      map("n", "<leader>fk", builtin.keymaps, "Find keymaps")
      map("n", "<leader>fz", builtin.current_buffer_fuzzy_find, "Find in current buffer")
      map("n", "<leader>fl", builtin.resume, "Open last picker")

      -- telescope git
      map("n", "<leader>gs", builtin.git_status, "Git status")
      map("n", "<leader>gc", builtin.git_commits, "Git commits")
      map("n", "<leader>gf", builtin.git_bcommits, "Current file git commits")

      -- telescope lsp
      map({ "n", "v", "x" }, "<leader>=", vim.lsp.buf.format, "Format current buffer")
      map("n", "<leader>dd", builtin.diagnostics, "Find diagnostics")
      map("n", "<leader>gd", builtin.lsp_definitions, "LSP definitions")
      map("n", "<leader>gr", builtin.lsp_references, "LSP references")
      map("n", "<leader>gI", builtin.lsp_implementations, "LSP implementations")
      map("n", "<leader>ds", builtin.lsp_document_symbols, "LSP document symbols")
      map("n", "<leader>ws", builtin.lsp_workspace_symbols, "LSP workspace symbols")

      -- open filepicker on start
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argv(0) == "" then
	    vim.defer_fn(function()
              require('telescope.builtin').find_files()
	    end, 10)
          end
        end,
      })
    '';
  };
}
