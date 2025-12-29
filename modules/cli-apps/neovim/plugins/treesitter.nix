{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ nvim-treesitter.withAllGrammars ];

    extraLuaConfig = /* lua */ ''
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<A-o>",
            node_incremental = "<A-o>",
            scope_incremental = false, -- "<A-up>"
            node_decremental = "<A-i>",
          },
        },
      })

      -- start treesitter
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "nix", "ruby", "markdown", "lua", "rust", "typescript", "javascript" },
        callback = function()
          vim.treesitter.start()
        end,
      })
    '';
  };
}
