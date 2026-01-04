{ ... }:
{
  programs.neovim.extraLuaConfig = /* lua */ ''
    vim.diagnostic.config({
      severity_sort = true,
      virtual_text = {
        prefix = "",
      },
      underline = true,
      float = {
        border = "rounded",
      },
      signs = {
        active = true,
        text = {
          [vim.diagnostic.severity.ERROR] = "󰅙 ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = "󰌵 ",
          [vim.diagnostic.severity.INFO] = " ",
        },
      },
      float = {
        border = "rounded",
        format = function(diagnostic)
          return string.format(
            "%s (%s) [%s]",
            diagnostic.message,
            diagnostic.source,
            diagnostic.code or diagnostic.user_data.lsp.code
          )
        end,
      },
    })
  '';
}
