{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.neovim;
in
{
  options.antob.cli-apps.neovim = with types; {
    enable = mkEnableOption "Whether or not to enable neovim";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];

    antob.home.extraOptions = {
      home.packages = with pkgs; [
        lua-language-server
        nixd
        nodePackages.bash-language-server
        vscode-langservers-extracted
        shfmt
      ];

      programs.neovim = {
        enable = true;

        viAlias = true;
        vimAlias = true;

        plugins = with pkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          vague-nvim
          catppuccin-nvim
          oil-nvim
          nvim-web-devicons
          telescope-nvim
          plenary-nvim
          nvim-lspconfig
          luasnip
          friendly-snippets
          blink-cmp
          telescope-fzf-native-nvim
          gitsigns-nvim
          nvim-autopairs
          vim-tmux-navigator
          lualine-nvim
          conform-nvim
        ];

        extraLuaConfig = /* lua */ ''
          -- globals
          vim.g.mapleader = ' '
          vim.g.maplocalleader = ' '
          vim.g.have_nerd_font = true
          vim.g.markdown_folding = false

          -- options
          vim.opt.laststatus = 3
          vim.opt.showmode = false

          vim.opt.clipboard = "unnamedplus"
          vim.opt.cursorline = true
          vim.opt.cursorlineopt = "line,number"

          -- Indenting
          vim.opt.expandtab = true
          vim.opt.shiftwidth = 2
          vim.opt.smartindent = true
          vim.opt.tabstop = 2
          vim.opt.softtabstop = 2

          vim.opt.ignorecase = true
          vim.opt.smartcase = true
          vim.opt.mouse = "a"

          -- Numbers
          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.numberwidth = 2
          vim.opt.ruler = false

          -- Max number of entries in popups
          vim.opt.pumheight = 20

          -- Show only one line in command line
          vim.opt.cmdheight = 0

          vim.opt.signcolumn = "yes"
          vim.opt.splitbelow = true
          vim.opt.splitright = true
          vim.opt.timeoutlen = 400
          vim.opt.winborder = "rounded"

          -- Undo and swap
          vim.opt.swapfile = false
          vim.opt.undofile = true
          vim.opt.undolevels = 10000
          vim.opt.backup = false

          -- interval for writing swap file to disk, also used by gitsigns
          vim.opt.updatetime = 250

          -- Search highlight
          vim.opt.hlsearch = false
          vim.opt.incsearch = true

          -- Sets how neovim will display certain whitespace characters in the editor.
          vim.opt.list = true
          vim.opt.listchars = {
            tab = "» ",
            trail = "·",
            nbsp = "␣",
          }

          -- Preview substitutions live, as you type!
          vim.opt.inccommand = "split"

          -- Misc
          vim.opt.completeopt = "menu,menuone,noselect"
          vim.opt.wrap = false
          vim.opt.termguicolors = true
          vim.opt.scrolloff = 8
          vim.opt.breakindent = true

          -- disable nvim intro
          vim.opt.shortmess:append "sI"

          -- go to previous/next line with h,l,left arrow and right arrow
          -- when cursor reaches end/beginning of line
          vim.opt.whichwrap:append "<>[]hl"

          vim.opt.fillchars = { eob = " " }

          vim.cmd("colorscheme vague")
          -- vim.cmd("colorscheme catppuccin-mocha")

          -- Keymaps
          local map = vim.keymap.set

          -- center buffer after ctrl u/d
          map("n", "<C-d>", "<C-d>zz")
          map("n", "<C-u>", "<C-u>zz")

          -- use ; to enter command mode
          map({ "n", "v", "x" }, ";", ":")
          map({ "n", "v", "x" }, ":", ";")

          -- yank to system clipboard
          map({ "v", "x", "n" }, "<C-y>", '"+y', { desc = "Yank to System clipboard." })
          map({ "v", "x", "n" }, "<leader>y", '"+y', { desc = "Yank to System clipboard." })

          -- reselect visual block after indent/outdent
          map("v", "<", "<gv")
          map("v", ">", ">gv")

          -- keep cursor position when joining lines
          map("n", "J", "mzJ`z")

          -- keep search term center in screen
          map("n", "n", "nzzzv")
          map("n", "N", "Nzzzv")
    
          -- do not store deleted text when pasting
          map("x", "<leader>p", '"_dP')
    
          -- delete to void register
          map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to void register" })

          -- never press Q
          map("n", "Q", "<nop>")

          -- clear highlight
          map({ "i", "n" }, "<ESC>", "<CMD>noh<CR><ESC>", { desc = "Clear highlights" })

          -- navigation
          map("i", "<C-b>", "<ESC>^i", { desc = "Move to beginning of line" })
          map("i", "<C-e>", "<End>", { desc = "Move to end of line" })
          map("n", "<C-h>", "<C-w>h", { desc = "Focus window left" })
          map("n", "<C-l>", "<C-w>l", { desc = "Focus window right" })
          map("n", "<C-j>", "<C-w>j", { desc = "Focus window down" })
          map("n", "<C-k>", "<C-w>k", { desc = "Focus window up" })

          -- save file
          map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })

          -- copy whole file
          map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "Copy whole file" })

          -- splits
          map("n", "--", "<CMD>split<CR>", { desc = "Split window horizontally" })
          map("n", "\\\\", "<CMD>vsplit<CR>", { desc = "Split window vertically" })

          -- buffers
          map("n", "<S-h>", "<CMD>bprevious<CR>", { desc = "Previous buffer" })
          map("n", "<S-l>", "<CMD>bnext<CR>", { desc = "Next buffer" })
          map("n", "<leader>bb", "<CMD>e #<CR>", { desc = "Switch to other buffer" })

          -- tabs
          map("n", "<leader><tab>l", "<CMD>tablast<CR>", { desc = "Last tab" })
          map("n", "<leader><tab>f", "<CMD>tabfirst<CR>", { desc = "First tab" })
          map("n", "<leader><tab>]", "<CMD>tabnext<CR>", { desc = "Next tab" })
          map("n", "<leader><tab>[", "<CMD>tabprevious<CR>", { desc = "Previous tab" })
          map("n", "<leader><tab>o", "<CMD>tabonly<CR>", { desc = "Close other tabs" })
          map("n", "<leader><tab><tab>", "<CMD>tabnew<CR>", { desc = "New tab" })
          map("n", "<leader><tab>c", "<CMD>tabclose<CR>", { desc = "Close tab" })

          -- oil
          map({ "n" }, "<leader>e", "<cmd>Oil<CR>")

          local builtin = require("telescope.builtin")
          local utils = require("telescope.utils")
          function all_files() builtin.find_files({ no_ignore = true, follow = true, hidden = true }) end
          function relative_files() builtin.find_files({ cwd = utils.buffer_dir() }) end

          -- telescope find
          map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
          map("n", "<C-p>", builtin.find_files, { desc = "Find files" })
          map("n", "<leader>fa", all_files, { desc = "Find all files" })
          map("n", "<leader>F", relative_files, { desc = "Find files relative to buffer" })
          map("n", "<leader>fw", builtin.live_grep, { desc = "Find words" })
          map("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
          map("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent files" })
          map("n", "<leader>fh", builtin.help_tags, { desc = "Find help page" })
          map("n", "<leader>fm", builtin.man_pages, { desc = "Find man page" })
          map("n", "<leader>lr", builtin.lsp_references)
          map("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
          map("n", "<leader>fz", builtin.current_buffer_fuzzy_find, { desc = "Find in current buffer" })
          map("n", "<leader>fl", builtin.resume, { desc = "Open last picker" })

          -- telescope git
          map("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
          map("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
          map("n", "<leader>gf", builtin.git_bcommits, { desc = "Current file git commits" })

          -- telescope lsp
          map({ "n", "v", "x" }, "<leader>=", vim.lsp.buf.format, { desc = "Format current buffer" })
          map("n", "<leader>dd", builtin.diagnostics, { desc = "Find diagnostics" })
          map("n", "<leader>gd", builtin.lsp_definitions, { desc = "LSP definitions" })
          map("n", "<leader>gr", builtin.lsp_references, { desc = "LSP references" })
          map("n", "<leader>gI", builtin.lsp_implementations, { desc = "LSP implementations" })
          map("n", "<leader>ds", builtin.lsp_document_symbols, { desc = "LSP document symbols" })
          map("n", "<leader>ws", builtin.lsp_workspace_symbols, { desc = "LSP workspace symbols" })

          -- Diagnostic
          vim.diagnostic.config({
            severity_sort = true,
            virtual_text = {
              prefix = "",
            },
            underline = true,
            float = {
              border = "rounded",
            },
            signs = { 
              active = true,
              text = {
                [vim.diagnostic.severity.ERROR] = "󰅙 ",
                [vim.diagnostic.severity.WARN]  = " ",
                [vim.diagnostic.severity.HINT]  = "󰌵 ",
                [vim.diagnostic.severity.INFO]  = " ",
              },
            },
            float = {
              border = "single",
              format = function(diagnostic)
                return string.format(
                  "%s (%s) [%s]",
                  diagnostic.message,
                  diagnostic.source,
                  diagnostic.code or diagnostic.user_data.lsp.code
                )
              end,
            },
          })

          -- Configure LSP
          vim.lsp.config("lua_ls", {
            settings = {
              Lua = {
		            workspace = {
		              ignoreDir = { ".devenv", ".direnv" },
                },
	            },
	          },
          })

          -- Enable LSP
          vim.lsp.enable({
            "lua_ls",
            "nixd",
            "rust_analyzer",
          })

          -- Configure plugins
          -- treesitter
          require("nvim-treesitter.configs").setup({
            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
              enable = true,
              keymaps = {
                init_selection = "<A-o>",
                node_incremental = "<A-o>",
                scope_incremental = false, -- "<A-up>"
                node_decremental = "<A-i>",
              },
            },
          })

          -- telescope
          local telescope = require("telescope")
          telescope.setup({
            defaults = {
              preview = { treesitter = false },
              color_devicons = true,
              prompt_prefix = "  ",
              selection_caret = " ",
              entry_prefix = " ",
              selection_strategy = "reset",
              sorting_strategy = "ascending",
              layout_strategy = "horizontal",
              results_title = false,
              dynamic_preview_title = true,
              file_ignore_patterns = {
                "^.git/",
                "^node_modules/",
                "^.devenv/",
                "^.direnv/",
              },
              borderchars = {
                "", -- top
                "", -- right
                "", -- bottom
                "", -- left
                "", -- top-left
                "", -- top-right
                "", -- bottom-right
                "", -- bottom-left
              },
              path_displays = { "smart" },
              layout_config = {
                height = 100,
                width = 400,
                prompt_position = "top",
                preview_cutoff = 40,
              },
              mappings = {
                i = {
                  ["<Esc>"] = "close",
                  ["<C-Down>"] = "cycle_history_next",
                  ["<C-Up>"] = "cycle_history_prev",
                },
              },
            }
          })
          telescope.load_extension("fzf")

          -- oil
          require("oil").setup({
            default_file_explorer = true,
            lsp_file_methods = {
              enabled = true,
              timeout_ms = 1000,
              autosave_changes = true,
            },
            columns = {
              "permissions",
              "icon",
            },
            float = {
              max_width = 0.7,
              max_height = 0.6,
              border = "rounded",
            },
          })

          -- gitsigns
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

          -- lualine
          require("lualine").setup({
            options = {
              globalstatus = true,
              icons_enabled = true,
              theme = "auto",
              component_separators = "|",
              section_separators = "",
            },
            sections = {
              lualine_c = { "filename" },
              lualine_y = {"progress", "lsp_status" },
            };
          })

          -- colorscheme
          -- require("vague").setup({ transparent = true })
          require("catppuccin").setup({
            -- flavour = "mocha",
            -- transparent_background = true,
          })

          -- autocomplete
          require("luasnip.loaders.from_vscode").lazy_load()
          require("blink.cmp").setup({
            signature = { enabled = true },
            completion = {
              trigger = { show_in_snippet = false },
              documentation = { auto_show = true, auto_show_delay_ms = 500 },
              menu = {
                auto_show = true,
                draw = {
                  treesitter = { "lsp" },
                  columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
                },
              },
            },
            keymap = {
              preset = "super-tab",
            },
          })

	        -- conform
	        require("conform").setup({
            formatters_by_ft = {
              bash = { "shfmt" },
              json = { "jq" },
              eruby = { "htmlbeautifier" },
              rust = { "rustfmt" },
              nix = { "nixfmt" },
              lua = { "stylua" },
              javascript = { "prettierd", "prettier", timeout_ms = 2000, stop_after_first = true },
              ["_"] = { "trim_whitespace", "trim_newlines" },
            },

            formatters = {
              shfmt = { command = "${lib.getExe pkgs.shfmt}" },
              stylua = { command = "${lib.getExe pkgs.stylua}" },
              htmlbeautifier = { command = "bundle", args = { "exec", "htmlbeautifier", "--keep-blank-lines", "1" } },
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

              return { timeout_ms = 500, lsp_format = "fallback" }
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

          -- misc plugins
          require("nvim-autopairs").setup({})

          -- Auto commands
          -- open filepicker on start
          vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
              if vim.fn.argv(0) == "" then
                require('telescope.builtin').find_files()
              end
            end,
          })

          -- highlight when yanking text
          vim.api.nvim_create_autocmd("TextYankPost", {
            callback = function()
              vim.highlight.on_yank()
            end,
          })

          -- start treesitter
          vim.api.nvim_create_autocmd("FileType", {
          	pattern = { 'nix', 'ruby', 'markdown', 'lua', 'rust', 'typescript', 'javascript' },
            callback = function() vim.treesitter.start() end,
          })

          -- close some filetypes with <q>
          vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("close_with_q", { clear = true }),
            pattern = {
              "PlenaryTestPopup",
              "help",
              "lspinfo",
              "man",
              "notify",
              "qf",
              "checkhealth",
            },
            callback = function(event)
              vim.bo[event.buf].buflisted = false
              vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
            end,
          })

          -- Resize neovim split when terminal is resized
          vim.api.nvim_create_autocmd("VimResized", {
            callback = function()
              vim.cmd("wincmd =")
            end,
          })

          -- Misc
          -- if a file is a .env or .envrc file, set the filetype to sh
          vim.filetype.add({
            filename = {
              [".env"] = "sh",
              [".envrc"] = "sh",
              ["*.env"] = "sh",
              ["*.envrc"] = "sh"
            }
          })
        '';
      };
    };
  };
}
