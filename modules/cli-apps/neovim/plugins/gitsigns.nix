{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ gitsigns-nvim ];

    initLua = /* lua */ ''
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
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")

          -- Navigation
          vim.keymap.set("n", "]g", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]g", bang = true })
            else
              gitsigns.nav_hunk("next")
            end
          end)

          vim.keymap.set("n", "[g", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[g", bang = true })
            else
              gitsigns.nav_hunk("prev")
            end
          end)
        end,
      })
    '';
  };
}
