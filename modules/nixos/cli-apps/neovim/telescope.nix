{ pkgs, config, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.cli-apps.neovim;

in {
  antob.home.extraOptions.programs.neovim.plugins = with pkgs.vimPlugins;
    mkIf cfg.enable [
      plenary-nvim
      telescope-fzf-native-nvim
      {
        plugin = telescope-nvim;
        type = "lua";
        config = # lua
          ''
            local actions = require("telescope.actions")
            require('telescope').setup {
              defaults = {
                mappings = {
                  i = {
                    ['<C-u>'] = false,
                    ['<C-d>'] = false,
                    ['<esc>'] = actions.close
                  },
                },
                prompt_prefix = " ",
                selection_caret = "❯ ",
                path_display = { "truncate" },
                selection_strategy = "reset",
                sorting_strategy = "ascending",
                layout_strategy = "horizontal",
                layout_config = {
                  horizontal = {
                    prompt_position = "top",
                    preview_width = 0.55,
                    results_width = 0.8,
                  };
                  vertical = {
                    mirror = false,
                  },
                  width = 0.87,
                  height = 0.8,
                  preview_cutoff = 120,
                },
              },
            }

            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>/', function()
              -- You can pass additional configuration to telescope to change theme, layout, etc.
              builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                  winblend = 10,
                  previewer = false,
              })
            end, { desc = 'Fuzzily search in current buffer' })
            vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
            vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Find files' })
            vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = 'Find old files' })
            vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Find keymaps' })
            vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Find help' })
            vim.keymap.set('n', '<leader>fw', builtin.live_grep, { desc = 'Find word' })
            vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Find diagnostics' })
            vim.keymap.set('n', '<leader>fj', builtin.jumplist, { desc = 'Find jumplist' })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })

            require('telescope').load_extension('fzf')
          '';
      }
    ];
}
