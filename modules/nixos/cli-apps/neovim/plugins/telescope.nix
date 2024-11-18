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
      local colors = {
        white = "#abb2bf",
        darker_black = "#1b1f27",
        black = "#1e222a", --  nvim bg
        black2 = "#252931",
        one_bg = "#282c34", -- real bg of onedark
        red = "#e06c75",
        green = "#98c379",
        blue = "#61afef",
        yellow = "#e7c787",
      }

      local TelescopeColor = {
        TelescopePromptPrefix = { fg = colors.red, bg = colors.black2 },
        TelescopeNormal = { bg = colors.darker_black },
        TelescopePreviewTitle = { fg = colors.black, bg = colors.green},
        TelescopePromptTitle = { fg = colors.black, bg = colors.red },
        TelescopeSelection = { fg = colors.white, bg = colors.black2 },
        TelescopeResultsDiffAdd = { fg = colors.green },
        TelescopeResultsDiffChange = { fg = colors.yellow },
        TelescopeResultsDiffDelete = { fg = colors.red },
        TelescopeMatching = { fg = colors.blue, bg = colors.one_bg },
        TelescopeBorder = { fg = colors.darker_black, bg = colors.darker_black },
        TelescopePromptBorder = { fg = colors.black2, bg = colors.black2 },
        TelescopePreviewBorder = { fg = colors.black2, bg = colors.black2 },
        TelescopeResultsBorder = { fg = colors.black2, bg = colors.black2 },
        TelescopePromptNormal = { fg = colors.white, bg = colors.black2 },
        TelescopeResultsTitle = { fg = colors.darker_black, bg = colors.darker_black },
        TelescopePromptPrefix = { fg = colors.red, bg = colors.black2 },
      }

      for hl, col in pairs(TelescopeColor) do
      	vim.api.nvim_set_hl(0, hl, col)
      end
    '';
  };
}
