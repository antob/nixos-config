{ pkgs, config, lib, ... }:

with lib;
let cfg = config.antob.cli-apps.neovim;

in {
  antob.home.extraOptions.programs.neovim.plugins = with pkgs.vimPlugins;
    mkIf cfg.enable [
      lsp-format-nvim
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = # lua
          ''
            local lspconfig = require('lspconfig')
            local lspformat = require("lsp-format")
            lspformat.setup {}

            local lsp_defaults = lspconfig.util.default_config
            lsp_defaults.capabilities = vim.tbl_deep_extend(
              'force',
              lsp_defaults.capabilities,
              require('cmp_nvim_lsp').default_capabilities()
            )

            function with_desc(options, desc)
              options.desc = desc
              return options
            end

            local opts = { noremap=true, silent=true }
            vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, with_desc(opts, 'Open diagnostics float'))
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, with_desc(opts, 'Prev diagnostic'))
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next, with_desc(opts, 'Next diagnostic'))
            vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, with_desc(opts, 'Add buffer diagnostics to the location list.'))

            local on_attach = function(client, bufnr)
              lspformat.on_attach(client)
              vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
              local bufopts = { noremap=true, silent=true, buffer=bufnr }
              vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, with_desc(bufopts, 'Goto declaration'))
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, with_desc(bufopts, 'Goto definition'))
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, with_desc(bufopts, 'Goto references'))
              vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, with_desc(bufopts, 'Goto implementation'))
              vim.keymap.set('n', 'K', vim.lsp.buf.hover, with_desc(bufopts, 'Display hover info'))
              vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, with_desc(bufopts, 'Displays signature information'))
              vim.keymap.set('n', '<space>r', vim.lsp.buf.rename, with_desc(bufopts, 'Rename symbol'))
              vim.keymap.set('n', '<space>a', vim.lsp.buf.code_action, with_desc(bufopts, 'Show code actions'))
              vim.keymap.set('n', '=', function()
                vim.lsp.buf.format { async = true }
              end, with_desc(bufopts, 'Format buffer'))
            end

            function add_lsp(binary, server, options)
              if vim.fn.executable(binary) == 1 then
                options.on_attach = on_attach
                server.setup(options)
              end
            end

            add_lsp("rust-analyzer", lspconfig.rust_analyzer, {})
            add_lsp("docker-langserver", lspconfig.dockerls, {})
            add_lsp("bash-language-server", lspconfig.bashls, {})
            add_lsp("nil", lspconfig.nil_ls, {
              settings = {
                ['nil'] = {
                  formatting = {
                    command = { "nixpkgs-fmt" },
                  },
                },
              },
            })
            add_lsp("pylsp", lspconfig.pylsp, {})
            add_lsp("solargraph", lspconfig.solargraph, {})
            add_lsp("tsserver", lspconfig.tsserver, {})
            add_lsp("lua-lsp", lspconfig.lua_ls, {
              cmd = { "lua-lsp" }
            })
          '';
      }
      {
        plugin = fidget-nvim;
        type = "lua";
        config = # lua
          ''
            -- Turn on lsp status information
            require('fidget').setup()
          '';
      }
    ];

  antob.home.extraOptions.home.packages = with pkgs; [
    rust-analyzer
    nil
    nixpkgs-fmt
    lua-language-server
  ];
}
