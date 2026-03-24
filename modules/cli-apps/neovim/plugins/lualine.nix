{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ lualine-nvim ];

    initLua = /* lua */ ''
      local custom_theme = require("lualine.themes.ayu_mirage")
      -- custom_theme.normal.c.bg = "#292c3c"
      -- custom_theme.inactive.c.bg = "#292c3c"

      require("lualine").setup({
        options = {
          globalstatus = false,
          icons_enabled = true,
          theme = custom_theme,
          component_separators = " ⃒",
          section_separators = "",
        },
        sections = {
          lualine_b = {
            { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
          },
          lualine_c = {
            { "filename", filestatus = true, path = 1 },
          },
          lualine_x = { "filetype" },
          lualine_y = {
            "progress",
            {
              "lsp_status",
              icon = "󰚩",
              symbols = {
                spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
                done = "󰗡",
                separator = " ",
              },
              ignore_lsp = { "copilot" },
              show_name = true,
              padding = { left = 1, right = 2 },
            },
          },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            { "filename", filestatus = true, path = 1 },
          },
          lualine_x = { "filetype", "progress", "location" },
          lualine_y = {},
          lualine_z = {},
        },
      })
    '';
  };
}
