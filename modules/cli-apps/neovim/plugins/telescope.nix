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
  };
}
