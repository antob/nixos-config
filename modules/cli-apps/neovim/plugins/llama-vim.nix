{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      llama-vim
    ];

    initLua = /* lua */ ''
      vim.api.nvim_set_hl(0, "llama_hl_fim_hint", { fg = "#787c99", ctermfg = 209 })
      vim.api.nvim_set_hl(0, "llama_hl_fim_info", { fg = "#444b6a", ctermfg = 119 })
      vim.g.llama_config = {
        enable_at_startup = false,
        -- endpoint = "http://desktob.antob.net:8012/infill",
        show_info = false,
      }
    '';
  };
}
