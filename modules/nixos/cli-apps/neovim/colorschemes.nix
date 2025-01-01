{
  colorschemes = {
    catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
        integrations = {
          cmp = true;
          gitsigns = true;
          notify = true;
          nvimtree = true;
          treesitter = true;
          telescope = true;
          which_key = true;
          indent_blankline = {
            enabled = true;
            scope_color = "surface2";
          };
          snacks = true;
          lsp_trouble = true;
          # copilot_vim = true;
          # native_lsp.enabled = true;
        };
      };
    };
  };
}
