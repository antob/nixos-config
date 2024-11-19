{ config, ... }:
let
  colors = config.antob.color-scheme.colors;
in
{
  plugins.telescope = {
    enable = true;
    settings = {
      defaults = {
        prompt_prefix = "  ";
        # selection_caret = "❯ ";
        selection_caret = " ";
        entry_prefix = " ";
        selection_strategy = "reset";
        sorting_strategy = "ascending";
        layout_strategy = "horizontal";
        # border = false;
        results_title = false;
        file_ignore_patterns = [
          "^.git/"
          "^node_modules/"
        ];
        layout_config = {
          prompt_position = "top";
          horizontal = {
            prompt_position = "top";
            preview_width = 0.55;
          };
          width = 0.87;
          height = 0.8;
        };
        mappings = {
          i = {
            "<Esc>" = {
              __raw = "require('telescope.actions').close";
            };
            "<C-Down>" = {
              __raw = "require('telescope.actions').cycle_history_next";
            };
            "<C-Up>" = {
              __raw = "require('telescope.actions').cycle_history_prev";
            };
          };
        };
      };
    };
    extensions = {
      fzf-native.enable = true;
    };
    luaConfig.post = ''
      local TelescopeColor = {
        TelescopePromptPrefix = { fg = '#${colors.base01}', bg = '#${colors.base10}' },
        TelescopeNormal = { bg = '#${colors.base13}' },
        TelescopePreviewTitle = { fg = '#${colors.base00}', bg = '#${colors.base02}'},
        TelescopePromptTitle = { fg = '#${colors.base00}', bg = '#${colors.base01}' },
        TelescopeSelection = { fg = '#${colors.base07}', bg = '#${colors.base12}' },
        TelescopeResultsDiffAdd = { fg = '#${colors.base02}' },
        TelescopeResultsDiffChange = { fg = '#${colors.base03}' },
        TelescopeResultsDiffDelete = { fg = '#${colors.base01}' },
        TelescopeMatching = { fg = '#${colors.base04}', bg = '#${colors.base10}' },
        TelescopeBorder = { fg = '#${colors.base13}', bg = '#${colors.base14}' },
        TelescopePromptBorder = { fg = '#${colors.base10}', bg = '#${colors.base10}' },
        TelescopePreviewBorder = { fg = '#${colors.base10}', bg = '#${colors.base10}' },
        TelescopeResultsBorder = { fg = '#${colors.base10}', bg = '#${colors.base10}' },
        TelescopePromptNormal = { fg = '#${colors.base07}', bg = '#${colors.base10}' },
        TelescopeResultsTitle = { fg = '#${colors.base13}', bg = '#${colors.base14}' },
        TelescopePromptPrefix = { fg = '#${colors.base01}', bg = '#${colors.base10}' },
      }

      for hl, col in pairs(TelescopeColor) do
      	vim.api.nvim_set_hl(0, hl, col)
      end
    '';
  };
}
