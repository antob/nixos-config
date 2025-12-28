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

    extraLuaConfig = /* lua */ ''
      require("luasnip.loaders.from_vscode").lazy_load()
      require("blink.cmp").setup({
        signature = { enabled = true },
        completion = {
          trigger = { show_in_snippet = false },
          list = {
            selection = {
              preselect = false,
              auto_insert = false,
            },
          },
          documentation = { auto_show = true, auto_show_delay_ms = 500 },
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
          ['<Esc>'] = { 'hide', 'fallback' },
          ['<CR>'] = { 'accept', 'fallback' },
        },
        cmdline = {
          keymap = {
            preset = "cmdline",
            ['<CR>'] = { 'select_and_accept', 'fallback' },
            ['<Esc>'] = { 'cancel', 'fallback' },
          },
          completion = {
           list = {
              selection = {
                preselect = false,
                auto_insert = false,
              },
            },
          },
        },
      })
    '';
  };
}
