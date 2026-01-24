{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ oil-nvim ];

    initLua = /* lua */ ''
      require("oil").setup({
        default_file_explorer = true,
        lsp_file_methods = {
          enabled = true,
          timeout_ms = 1000,
          autosave_changes = true,
        },
        columns = {
          "permissions",
          "icon",
        },
        float = {
          max_width = 0.7,
          max_height = 0.6,
          border = "rounded",
        },
        keymaps = {
          ["q"] = { "actions.close", mode = "n" },
          ["<leader>o"] = { "actions.close", mode = "n" },
        },
      })
    '';
  };
}
