{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ lualine-nvim ];

    extraLuaConfig = /* lua */ ''
      require("lualine").setup({
        options = {
          globalstatus = false,
          icons_enabled = true,
          theme = "auto",
          component_separators = "│",
          section_separators = "",
        },
        sections = {
          lualine_b = {
            "branch",
            { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
          },
          lualine_c = {
            { "filename", filestatus = true, path = 1 },
          },
          lualine_y = {
            "progress",
            "lsp_status",
          },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            { "filename", filestatus = true, path = 1 },
          },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
      })
    '';
  };
}
