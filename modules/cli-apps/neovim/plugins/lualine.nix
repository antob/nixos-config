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
          globalstatus = true,
          icons_enabled = true,
          theme = "auto",
          component_separators = "|",
          section_separators = "",
        },
        sections = {
          lualine_b = {
            "branch",
            "diff",
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
        winbar = {
          lualine_z = {
            { "filename", filestatus = true, path = 1, color = { fg = "#6c7086", bg = "#313244" } },
          },
        },
        inactive_winbar = {
          lualine_z = {
            { "filename", filestatus = true, path = 1, color = { fg = "#6c7086", bg = "#1a1b26" } },
          },
        },
      })
    '';
  };
}
