{
  pkgs,
  lib,
  ...
}:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ conform-nvim ];

    initLua = /* lua */ ''
      require("conform").setup({
        formatters_by_ft = {
          bash = { "shfmt" },
          json = { "jq" },
          ruby = { "standardrb" },
          eruby = { "herb_format" },
          rust = { "rustfmt" },
          nix = { "nixfmt", "injected" },
          lua = { "stylua" },
          python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          vue = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          less = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          jsonc = { "prettier" },
          yaml = { "prettier" },
          just = { "just" },
          make = { "bake" },
          ["_"] = { "trim_whitespace", "trim_newlines" },
        },

        default_format_opts = {
          lsp_format = "fallback",
        },

        formatters = {
          shfmt = { command = "${lib.getExe pkgs.shfmt}" },
          bake = { command = "${lib.getExe pkgs.mbake}" },
          prettierd = { command = "${lib.getExe pkgs.prettierd}" },
          prettier = { command = "${lib.getExe pkgs.prettier}" },
          stylua = {
            command = "${lib.getExe pkgs.stylua}",
            args = {
              "--indent-type",
              "Spaces",
              "--indent-width",
              "2",
              "--search-parent-directories",
              "--respect-ignores",
              "--stdin-filepath",
              "$FILENAME",
              "-",
            },
          },
          standardrb = {
            command = "bundle",
            args = {
              "exec",
              "standardrb",
              "--stdin",
              "foo.rb",
              "--fix",
              "--stderr",
            },
          },
          herb_format = {
            command = "${pkgs.herb-tools}/bin/herb-format",
            args = {
              "-",
            },
          },
        },

        format_on_save = function(bufnr)
          -- Disable autoformat on certain filetypes
          local ignore_filetypes = { "sql", "java" }
          if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
            return
          end
          -- Disable with a global or buffer-local variable
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          -- Disable autoformat for files in a certain path
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          if bufname:match("/node_modules/") then
            return
          end

          return { timeout_ms = 1500, lsp_format = "fallback" }
        end,
      })

      -- User commands
      -- format
      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        require("conform").format({ async = true, lsp_format = "fallback", range = range })
      end, { range = true })

      -- format disable
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          -- FormatDisable! will disable formatting just for this buffer
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })

      -- format enable
      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })
    '';
  };
}
