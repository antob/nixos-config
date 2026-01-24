{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
    ];

    initLua = /* lua */ ''
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")

      -- Select keymappings
      vim.keymap.set({ "x", "o" }, "af", function()
        select.select_textobject("@call.outer", "textobjects")
      end, { desc = "Function outer region" })
      vim.keymap.set({ "x", "o" }, "if", function()
        select.select_textobject("@call.inner", "textobjects")
      end, { desc = "Function inner region" })

      vim.keymap.set({ "x", "o" }, "am", function()
        select.select_textobject("@function.outer", "textobjects")
      end, { desc = "Method outer region" })
      vim.keymap.set({ "x", "o" }, "im", function()
        select.select_textobject("@function.inner", "textobjects")
      end, { desc = "Method inner region" })

      vim.keymap.set({ "x", "o" }, "ac", function()
        select.select_textobject("@class.outer", "textobjects")
      end, { desc = "Class outer region" })
      vim.keymap.set({ "x", "o" }, "ic", function()
        select.select_textobject("@class.inner", "textobjects")
      end, { desc = "Class inner region" })

      vim.keymap.set({ "x", "o" }, "aa", function()
        select.select_textobject("@parameter.outer", "textobjects")
      end, { desc = "Parameter outer region" })
      vim.keymap.set({ "x", "o" }, "ia", function()
        select.select_textobject("@parameter.inner", "textobjects")
      end, { desc = "Parameter inner region" })

      vim.keymap.set({ "x", "o" }, "a=", function()
        select.select_textobject("@assignment.outer", "textobjects")
      end, { desc = "Assignment outer region" })
      vim.keymap.set({ "x", "o" }, "i=", function()
        select.select_textobject("@assignment.inner", "textobjects")
      end, { desc = "Assignment inner region" })

      -- Move keymappings
      vim.keymap.set({ "n", "x", "o" }, "]m", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next method" })
      vim.keymap.set({ "n", "x", "o" }, "]M", function()
        move.goto_next_end("@function.outer", "textobjects")
      end, { desc = "End of next method" })
      vim.keymap.set({ "n", "x", "o" }, "[m", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Previous method" })
      vim.keymap.set({ "n", "x", "o" }, "[M", function()
        move.goto_previous_end("@function.outer", "textobjects")
      end, { desc = "End of previous method" })

      vim.keymap.set({ "n", "x", "o" }, "]c", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class" })
      vim.keymap.set({ "n", "x", "o" }, "]C", function()
        move.goto_next_end("@class.outer", "textobjects")
      end, { desc = "End of next class" })
      vim.keymap.set({ "n", "x", "o" }, "[c", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Previous class" })
      vim.keymap.set({ "n", "x", "o" }, "[C", function()
        move.goto_previous_end("@class.outer", "textobjects")
      end, { desc = "End of previous class" })

      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@call.outer", "textobjects")
      end, { desc = "Next function" })
      vim.keymap.set({ "n", "x", "o" }, "]F", function()
        move.goto_next_end("@call.outer", "textobjects")
      end, { desc = "End of next function" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@call.outer", "textobjects")
      end, { desc = "Previous function" })
      vim.keymap.set({ "n", "x", "o" }, "[F", function()
        move.goto_previous_end("@call.outer", "textobjects")
      end, { desc = "End of previous function" })

      vim.keymap.set({ "n", "x", "o" }, "]a", function()
        move.goto_next_start("@parameter.outer", "textobjects")
      end, { desc = "Next parameter" })
      vim.keymap.set({ "n", "x", "o" }, "]A", function()
        move.goto_next_end("@parameter.outer", "textobjects")
      end, { desc = "End of next parameter" })
      vim.keymap.set({ "n", "x", "o" }, "[a", function()
        move.goto_previous_start("@parameter.outer", "textobjects")
      end, { desc = "Previous parameter" })
      vim.keymap.set({ "n", "x", "o" }, "[A", function()
        move.goto_previous_end("@parameter.outer", "textobjects")
      end, { desc = "End of previous parameter" })

      -- start treesitter
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "nix",
          "ruby",
          "markdown",
          "lua",
          "rust",
          "typescript",
          "typescriptreact",
          "javascript",
          "javascriptreact",
          "python",
        },
        callback = function()
          vim.treesitter.start()
        end,
      })
    '';
  };
}
