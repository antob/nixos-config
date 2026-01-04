{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      llama-vim
    ];

    extraLuaConfig = /* lua */ ''
      vim.g.llama_config = {
        endpoint = "http://desktob.antob.net:8012/infill",
        show_info = 1,
      }

      vim.api.nvim_set_hl(0, "llama_hl_hint", { link = "LspInlayHint" })
    '';
  };
}
