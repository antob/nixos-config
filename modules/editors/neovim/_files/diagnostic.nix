{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      tiny-inline-diagnostic-nvim
    ];

    initLua = /* lua */ ''
      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = false,
        underline = true,
        signs = {
          active = true,
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      vim.cmd([[
        highlight DiagnosticUnderlineError gui=undercurl
        highlight DiagnosticUnderlineWarn gui=undercurl
        highlight DiagnosticUnderlineInfo gui=undercurl
        highlight DiagnosticUnderlineHint gui=undercurl
      ]])

      require("tiny-inline-diagnostic").setup({
        preset = "nonerdfont",
        options = {
          multilines = {
            enabled = true,
          },
        },
        signs = {
          left = "░",
          right = "░",
          diag = " ",
          arrow = "   ",
        },
        blend = {
          factor = 0.22,
        },
      })
    '';
  };
}
