{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    lua-language-server
    nixd
    nodePackages.bash-language-server
    vscode-langservers-extracted
    shfmt
  ];

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ nvim-lspconfig ];

    extraLuaConfig = /* lua */ ''
      -- LSP Keymaps Setup
      local function setup_keymaps(bufnr)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        -- Hover & Signature (no prefix)
        map("n", "K", function()
          vim.lsp.buf.hover({ border = "rounded", max_height = 25, max_width = 120 })
        end, "Hover")
        map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
        map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

        -- Navigation (g prefix) - gd, gD, gr, gI, gy handled by Snacks
        map("n", "gt", vim.lsp.buf.type_definition, "Type Definition")
        map("n", "<leader>v", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Definition in Split")

        -- Diagnostics navigation ([ and ] prefix)
        map("n", "[d", function()
          vim.diagnostic.jump({ count = -1 })
        end, "Prev Diagnostic")
        map("n", "]d", function()
          vim.diagnostic.jump({ count = 1 })
        end, "Next Diagnostic")

        -- <leader>c = Code
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
        map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostic")
        -- cf (format) handled by conform.lua

        -- <leader>l = LSP
        map("n", "<leader>li", "<cmd>LspInfo<cr>", "LSP Info")
        map("n", "<leader>lr", "<cmd>LspRestart<cr>", "LSP Restart")
        map("n", "<leader>lh", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
        end, "Toggle Inlay Hints")
      end

      -- LSP Attach Handler
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          setup_keymaps(bufnr)
          vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

          -- Document highlight on cursor hold
          if client.server_capabilities.documentHighlightProvider then
            local group = vim.api.nvim_create_augroup("LspDocumentHighlight_" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = bufnr,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = bufnr,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      -- lua_ls
      vim.lsp.config("lua_ls", {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
              path ~= vim.fn.stdpath("config")
              and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
            then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
            runtime = {
              version = "LuaJIT",
              path = {
                "lua/?.lua",
                "lua/?/init.lua",
              },
            },
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
              },
            },
          })
        end,
        settings = {
          Lua = {
            workspace = {
              ignoreDir = { ".devenv", ".direnv" },
            },
          },
        },
      })

      -- Enable LSPs
      vim.lsp.enable({
        "lua_ls",
        "nixd",
        "rust_analyzer",
      })
    '';
  };
}
