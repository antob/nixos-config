{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    lua-language-server
    nixd
    bash-language-server
    typescript-language-server
    vscode-langservers-extracted
    shfmt
    ruff
    ty
    just-lsp
  ];

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [ nvim-lspconfig ];

    initLua = /* lua */ ''
      -- Enable LSPs
      vim.lsp.enable({
        "lua_ls",
        "nixd",
        "rust_analyzer",
        "ruby_lsp",
        "herb_ls",
        "ts_ls",
        "cssls",
        "ty",
        "m68k",
        "just",
      })

      -- Configure LSPs
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

      -- ruby_lsp
      vim.lsp.config("ruby_lsp", {
        cmd = { "bundle", "exec", "ruby-lsp" },
      })

      -- herb_ls
      vim.lsp.config("herb_ls", {
        cmd = { "${pkgs.herb-tools}/bin/herb-language-server", "--stdio" },
      })

      -- m68k-lsp-server
      vim.lsp.config("m68k", {
        cmd = { "${pkgs.m68k-lsp-server}/bin/m68k-lsp-server", "--stdio" },
        init_options = {
          format = {
            case = {
              instruction = "lower",
              directive = "upper",
              control = "upper",
              sectionType = "upper",
              register = "lower",
              hex = "lower",
            },
            finalNewLine = true,
          },
        },
      })

      -- Disable sematic tokens to stop color scheme changes when LSP start
      vim.lsp.semantic_tokens.enable(false)

      -- LSP Keymaps Setup
      local function setup_keymaps(bufnr)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        -- Hover & Signature (no prefix)
        map("n", "K", function()
          vim.lsp.buf.hover({ border = "rounded", max_height = 25, max_width = 120 })
        end, "Hover")
        map({ "n", "i" }, "<C-s>", vim.lsp.buf.signature_help, "Signature Help")

        -- Navigation (g prefix) - gd, gD, gr, gI, gy handled by Snacks
        map("n", "gt", Snacks.picker.lsp_type_definitions, "Type Definition")
        map("n", "<leader>v", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Definition in Split")
        map("n", "gd", Snacks.picker.lsp_definitions, "LSP definitions")
        vim.keymap.set("n", "gr", Snacks.picker.lsp_references, { nowait = true, desc = "LSP references" })
        map("n", "gI", function()
          Snacks.picker.lsp_implementations()
        end, "LSP implementations")

        -- <leader>c = Code
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
        map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostic")

        -- <leader>l = LSP
        map("n", "<leader>lh", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
        end, "Toggle Inlay Hints")

        map("n", "<C-w>]", function()
          vim.api.nvim_command("vsplit")
          vim.lsp.buf.definition()
        end, "Split window vertically and goto definition")
        map("n", "<C-w><C-]>", function()
          vim.api.nvim_command("vsplit")
          vim.lsp.buf.definition()
        end, "Split window vertically and goto definition")
      end

      -- Helper functions

      -- Target clients: by name(s) passed as args, or the ones from the current buffer
      local function get_target_clients(fargs)
        if fargs and #fargs > 0 then
          local clients = {}
          for _, name in ipairs(fargs) do
            vim.list_extend(clients, vim.lsp.get_clients({ name = name }))
          end
          return clients
        end
        return vim.lsp.get_clients({ bufnr = 0 })
      end

      -- Autocomplete with names of active clients
      local function complete_client_names(arglead)
        local seen, names = {}, {}
        for _, client in ipairs(vim.lsp.get_clients()) do
          if not seen[client.name] and vim.startswith(client.name, arglead) then
            seen[client.name] = true
            table.insert(names, client.name)
          end
        end
        return names
      end

      -- User commands

      -- ── :LspInfo ─────────────────────────────────────────────────────────
      vim.api.nvim_create_user_command("LspInfo", ":checkhealth vim.lsp", { desc = "Alias to `:checkhealth vim.lsp`" })

      -- ── :LspLog ──────────────────────────────────────────────────────────
      vim.api.nvim_create_user_command("LspLog", function()
        vim.cmd(string.format("tabnew %s", vim.lsp.log.get_filename()))
      end, {
        desc = "Opens LSP client log",
      })

      -- ── :LspList ─────────────────────────────────────────────────────────
      vim.api.nvim_create_user_command("LspList", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if vim.tbl_isempty(clients) then
          vim.notify("No LSP clients attached to this buffer", vim.log.levels.WARN)
          return
        end
        local lines = {}
        for _, c in ipairs(clients) do
          table.insert(lines, string.format("[%d] %s", c.id, c.name))
          table.insert(lines, string.format("    root: %s", c.root_dir or "(no root_dir)"))
          table.insert(
            lines,
            string.format("    cmd:  %s", type(c.config.cmd) == "table" and table.concat(c.config.cmd, " ") or "(function)")
          )
        end
        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end, { desc = "List LSP clients attached to the current buffer" })

      -- ── :LspStop ─────────────────────────────────────────────────────────
      -- :LspStop            → stops the clients of the current buffer
      -- :LspStop intelephense → stops a client by name
      -- :LspStop!           → forces shutdown (SIGKILL)
      vim.api.nvim_create_user_command("LspStop", function(opts)
        local clients = get_target_clients(opts.fargs)
        if vim.tbl_isempty(clients) then
          vim.notify("No clients found to stop", vim.log.levels.WARN)
          return
        end
        for _, client in ipairs(clients) do
          client:stop(opts.bang)
          vim.notify("Stopped: " .. client.name)
        end
      end, {
        nargs = "*",
        bang = true,
        complete = complete_client_names,
        desc = "Stop LSP clients",
      })

      -- ── :LspStart ────────────────────────────────────────────────────────
      -- Re-triggers the FileType event of the current buffer, which re-executes
      -- autostart (works with both lspconfig and vim.lsp.enable)
      vim.api.nvim_create_user_command("LspStart", function()
        vim.api.nvim_exec_autocmds("FileType", { buffer = 0 })
        vim.notify("LSP autostart re-triggered for this buffer")
      end, { desc = "Start LSP on the current buffer" })

      -- ── :LspRestart ──────────────────────────────────────────────────────
      -- Saves config and buffers for each client, stops it, and after a delay
      -- re-starts it re-attaching the same buffers.
      -- Works regardless of how the client was started (lspconfig, vim.lsp.enable, etc.)
      vim.api.nvim_create_user_command("LspRestart", function(opts)
        local clients = get_target_clients(opts.fargs)
        if vim.tbl_isempty(clients) then
          vim.notify("No clients found to restart", vim.log.levels.WARN)
          return
        end

        local saved = {}
        for _, client in ipairs(clients) do
          table.insert(saved, {
            name = client.name,
            config = client.config,
            bufs = vim.tbl_keys(client.attached_buffers or {}),
          })
          client:stop(opts.bang)
        end

        vim.defer_fn(function()
          for _, item in ipairs(saved) do
            for _, buf in ipairs(item.bufs) do
              if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
                -- vim.lsp.start reuses the client if one already exists with the same config
                vim.lsp.start(item.config, { bufnr = buf })
              end
            end
            vim.notify("Restarted: " .. item.name)
          end
        end, 500)
      end, {
        nargs = "*",
        bang = true,
        complete = complete_client_names,
        desc = "Restart LSP clients",
      })

      -- ── :LspCapabilities ─────────────────────────────────────────────────
      -- Useful to know if the server supports formatting, inlayHints, etc.
      vim.api.nvim_create_user_command("LspCapabilities", function(opts)
        local clients = get_target_clients(opts.fargs)
        if vim.tbl_isempty(clients) then
          vim.notify("No LSP clients in this buffer", vim.log.levels.WARN)
          return
        end
        for _, client in ipairs(clients) do
          -- Opens in a scratch buffer so you can search with /
          local buf = vim.api.nvim_create_buf(false, true)
          local lines = vim.split(vim.inspect(client.server_capabilities), "\n")
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.api.nvim_buf_set_name(buf, "capabilities://" .. client.name)
          vim.bo[buf].filetype = "lua"
          vim.cmd.tabnew()
          vim.api.nvim_win_set_buf(0, buf)
        end
      end, {
        nargs = "*",
        complete = complete_client_names,
        desc = "View LSP server capabilities",
      })

      -- LSP Attach Handler
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          if client.name == "copilot" then
            -- Do not add keymaps for copilot
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
    '';
  };
}
