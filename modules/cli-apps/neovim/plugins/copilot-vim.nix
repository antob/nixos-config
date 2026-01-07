{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      copilot-vim
    ];

    extraLuaConfig = /* lua */ ''
      vim.g.copilot_lsp_settings = {
        telemetry = {
          telemetryLevel = "off",
        },
      }

      vim.g.copilot_filetypes = {
        dotenv = false,
      }
    '';
  };
}
