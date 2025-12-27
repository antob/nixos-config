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
        },
      })
    '';
  };
}
