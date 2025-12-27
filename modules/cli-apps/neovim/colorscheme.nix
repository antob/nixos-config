{
  pkgs,
  lib,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      vague-nvim
      catppuccin-nvim
    ];

    extraLuaConfig = lib.mkOrder 210 /* lua */ ''
      vim.cmd("colorscheme vague")
      -- vim.cmd("colorscheme catppuccin-mocha")

      require("vague").setup({ transparent = true })
      -- require("catppuccin").setup({
      --   -- flavour = "mocha",
      --   -- transparent_background = true,
      -- })
    '';
  };
}
