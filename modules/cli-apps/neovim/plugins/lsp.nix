{
  plugins = {
    lsp = {
      enable = true;
      inlayHints = true;
      keymaps = {
        diagnostic = {
          "[d" = {
            action = "goto_prev";
            desc = "Previous diagnostic";
          };
          "]d" = {
            action = "goto_next";
            desc = "Next diagnostic";
          };
          "<leader>do" = {
            action = "setloclist";
            desc = "Diagnostic loclist";
          };
        };
        lspBuf = {
          "K" = {
            action = "hover";
            desc = "Show documentation";
          };
          "gD" = {
            action = "declaration";
            desc = "Go to declaration";
          };
          "gy" = {
            action = "type_definition";
            desc = "Go to definition";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "Show code actions";
          };
          "<leader>cr" = {
            action = "rename";
            desc = "Rename symbol";
          };
          "<leader>wl" = {
            action = "list_workspace_folders";
            desc = "List workspace folders";
          };
          "<leader>wr" = {
            action = "remove_workspace_folder";
            desc = "Remove workspace folder";
          };
          "<leader>wa" = {
            action = "add_workspace_folder";
            desc = "Add workspace folder";
          };
        };
        extra = [
          {
            mode = "n";
            key = "gd";
            action = "<cmd>Telescope lsp_definitions<CR>";
            options.desc = "Telescope definitions";
          }
          {
            mode = "n";
            key = "gr";
            action = "<cmd>Telescope lsp_references<CR>";
            options.desc = "Telescope references";
          }
          {
            mode = "n";
            key = "gI";
            action = "<cmd>Telescope lsp_implementations<CR>";
            options.desc = "Telescope implementations";
          }
          {
            mode = "n";
            key = "<leader>ds";
            action = "<cmd>Telescope lsp_document_symbols<CR>";
            options.desc = "Telescope document symbols";
          }
          {
            mode = "n";
            key = "<leader>ws";
            action = "<cmd>Telescope lsp_workspace_symbols<CR>";
            options.desc = "Telescope workspace symbols";
          }

        ];
      };
      # Re-enable semantic tokens on NeoVim 0.10.3.
      # See https://github.com/neovim/neovim/issues/30675
      capabilities = ''
        capabilities.semanticTokensProvider = nil
      '';
      preConfig = ''
        vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
          vim.lsp.handlers.hover,
          {border = 'single'}
        )

        vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
          vim.lsp.handlers.signature_help,
          {border = 'single'}
        )
      '';

      postConfig = ''
        local signs = { Error = "󰅙 ", Warn = " ", Hint = "󰌵 ", Info = "󰋼 " }
        for type, icon in pairs(signs) do
          local hl = "DiagnosticSign" .. type
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end

        -- Default border style
        --local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
        --function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        --  opts = opts or {}
        --  opts.border = "rounded"
        --  return orig_util_open_floating_preview(contents, syntax, opts, ...)
        --end
      '';

      servers = {
        jsonls.enable = true;
        marksman.enable = true;
        nil_ls = {
          enable = true;
          extraOptions = {
            offset_encoding = "utf-8";
            formatting = {
              command = [ "nixfmt" ];
            };
          };
        };
        yamlls.enable = true;
        ruby_lsp = {
          enable = true;
          package = null;
          cmd = [
            "bundle"
            "exec"
            "ruby-lsp"
          ];
          extraOptions = {
            single_file_support = false;
            init_options = {
              formatter = "standard";
              linters = [ "standard" ];
            };
          };
        };
      };
    };
    rustaceanvim.enable = true;
  };
}
