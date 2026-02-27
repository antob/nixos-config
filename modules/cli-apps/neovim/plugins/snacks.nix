{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      snacks-nvim
    ];

    initLua = /* lua */ ''
      require("snacks").setup({
        bigfile = { enabled = true },
        dashboard = { enabled = false },
        explorer = { enabled = false },
        indent = { enabled = false },
        input = { enabled = false },
        scratch = { enabled = true },

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
            wo = { winhighlight = "FloatBorder:PmenuBorder" },
            height = 0.99,
            width = 0.99,
          },
          zoom_indicator = {
            text = " 󰊓 ",
            row = 0,
          },
        },
      })

      -- Make SnacksPickerBorder use the PmenuExtra highlight group
      vim.api.nvim_set_hl(0, "SnacksPickerBorder", { link = "PmenuExtra" })
    '';
  };
}
