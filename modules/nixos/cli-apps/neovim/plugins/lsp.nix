{
  plugins.lsp = {
    enable = true;
    inlayHints = true;
    keymaps = {
      diagnostic = {
        "<leader>D" = "open_float";
        "[d" = "goto_prev";
        "]d" = "goto_next";
        "<leader>do" = "setloclist";
      };
      lspBuf = {
        "K" = "hover";
        "gD" = "declaration";
        "gd" = "definition";
        "gr" = "references";
        "gI" = "implementation";
        "gy" = "type_definition";
        # "<C-k>" = "signature_help";

        "<leader>ca" = "code_action";
        "<leader>cr" = "rename";
        "<leader>wl" = "list_workspace_folders";
        "<leader>wr" = "remove_workspace_folder";
        "<leader>wa" = "add_workspace_folder";
      };
    };
    preConfig = ''
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
        vim.lsp.handlers.hover,
        {border = 'solid'}
      )

      vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
        vim.lsp.handlers.signature_help,
        {border = 'solid'}
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
      nixd.enable = true;
      yamlls.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      ruby_lsp = {
        enable = true;
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

  # plugins = {
  #   conform-nvim.settings.formatters_by_ft.rust = [ "rustfmt" ];
  #   rustaceanvim = {
  #     enable = true;
  #     settings = {
  #       # dap.adapter = {
  #       #   command = "${pkgs.lldb_19}/bin/lldb-dap";
  #       #   type = "executable";
  #       # };
  #       tools.enable_clippy = true;
  #       server = {
  #         default_settings = {
  #           inlayHints = {
  #             lifetimeElisionHints = {
  #               enable = "always";
  #             };
  #           };
  #           rust-analyzer = {
  #             cargo = {
  #               allFeatures = true;
  #             };
  #             check = {
  #               command = "clippy";
  #             };
  #           };
  #         };
  #       };
  #     };
  #   };
  # };
}
