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
          map("n", "]g", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]g", bang = true })
            else
              gitsigns.nav_hunk("next")
            end
          end)

          map("n", "[g", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[g", bang = true })
            else
              gitsigns.nav_hunk("prev")
            end
          end)

          -- Actions
          map("n", "<leader>hs", gitsigns.stage_hunk, "Stage Git Hunk")
          map("n", "<leader>hr", gitsigns.reset_hunk, "Reset Git Hunk")

          map("v", "<leader>hs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, "Stage Git Hunk (Visual)")

          map("v", "<leader>hr", function()
            gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, "Reset Git Hunk (Visual)")

          map("n", "<leader>hS", gitsigns.stage_buffer, "Stage Buffer")
          map("n", "<leader>hR", gitsigns.reset_buffer, "Reset Buffer")
          map("n", "<leader>hp", gitsigns.preview_hunk, "Preview Git Hunk")
          map("n", "<leader>hi", gitsigns.preview_hunk_inline, "Preview Git Hunk (Inline)")

          map("n", "<leader>hb", function()
            gitsigns.blame_line({ full = true })
          end, "Git Blame Line")

          map("n", "<leader>hd", gitsigns.diffthis, "Git Diff Index")

          map("n", "<leader>hD", function()
            gitsigns.diffthis("~")
          end, "Git Diff HEAD")

          map("n", "<leader>hQ", function()
            gitsigns.setqflist("all")
          end, "Git Set QF List (All)")
          map("n", "<leader>hq", gitsigns.setqflist, "Git Set QF List (Current)")

          -- Toggles
          map("n", "<leader>tb", gitsigns.toggle_current_line_blame, "Toggle Current Line Blame")
          map("n", "<leader>tw", gitsigns.toggle_word_diff, "Toggle Word Diff")

          -- Text object
          map({ "o", "x" }, "ih", gitsigns.select_hunk)
        end,
      })
    '';
  };
}
