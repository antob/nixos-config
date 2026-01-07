{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      snacks-nvim
    ];

    extraLuaConfig = /* lua */ ''
      require("snacks").setup({
        bigfile = { enabled = true },
        dashboard = { enabled = false },
        explorer = { enabled = false },
        indent = { enabled = false },
        input = { enabled = false },

        picker = {
          enabled = true,
          ui_select = true,
          win = {
            -- input window
            input = {
              keys = {
                ["<Esc>"] = { "close", mode = { "n", "i" } },
              },
            },
          },
        },

        notifier = { enabled = true },
        quickfile = { enabled = false },
        scope = { enabled = false },
        scroll = { enabled = false },
        statuscolumn = { enabled = false },
        words = { enabled = false },
        styles = {
          lazygit = {
            border = "rounded",
            wo = { winhighlight = "FloatBorder:PmenuBorder" },
          },
        },
      })
    '';
  };
}
