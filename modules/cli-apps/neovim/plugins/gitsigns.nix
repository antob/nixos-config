{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ gitsigns-nvim ];

    extraLuaConfig = /* lua */ ''
      require("gitsigns").setup({
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
        },
        signcolumn = true,
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          changedelete = { text = "󱕖" },
          delete = { text = "󰍵" },
          topdelete = { text = "‾" },
          untracked = { text = "┆" },
        },
        watch_gitdir = { follow_files = true },
      })
    '';
  };
}
