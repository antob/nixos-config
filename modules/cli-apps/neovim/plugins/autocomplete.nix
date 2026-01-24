{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      luasnip
      friendly-snippets
      blink-cmp
    ];

    initLua = /* lua */ ''
      require("luasnip.loaders.from_vscode").lazy_load()
      require("blink.cmp").setup({
        signature = { enabled = true },
        completion = {
          trigger = {
            show_in_snippet = false,
            show_on_trigger_character = true,
            show_on_keyword = false,
          },
          list = {
            selection = {
              preselect = true,
              auto_insert = false,
            },
          },
          documentation = { auto_show = true, auto_show_delay_ms = 500 },
          ghost_text = { enabled = false },
          menu = {
            auto_show = true,
            draw = {
              treesitter = { "lsp" },
              columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
            },
          },
        },
        keymap = {
          preset = "super-tab",
          ["<Esc>"] = { "cancel", "fallback" },
          ["<CR>"] = { "accept", "fallback" },
        },
        cmdline = {
          keymap = {
            preset = "none",
            ["<CR>"] = { "select_and_accept", "fallback" },
            ["<Esc>"] = { "cancel", "fallback" },
            ["<Tab>"] = { "show_and_insert", "select_next", "fallback" },
            ["<S-Tab>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<Up>"] = { "select_prev", "fallback" },
          },
          completion = {
            list = {
              selection = {
                preselect = true,
                auto_insert = true,
              },
            },
          },
        },
      })

      -- hide copilot suggestions when blink menu is open
      vim.api.nvim_create_autocmd("User", {
        pattern = "BlinkCmpMenuOpen",
        callback = function()
          vim.b.copilot_suggestion_hidden = true
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "BlinkCmpMenuClose",
        callback = function()
          vim.b.copilot_suggestion_hidden = false
        end,
      })
    '';
  };
}
