{ ... }:
{
  programs.neovim.initLua = /* lua */ ''
    -- center buffer after ctrl u/d
    map("n", "<C-d>", "<C-d>zz")
    map("n", "<C-u>", "<C-u>zz")

    -- yank to system clipboard
    map({ "v", "x", "n" }, "<leader>y", '"+y', "Yank to System clipboard.")

    -- keep cursor position when joining lines
    map("n", "J", "mzJ`z")

    -- do not store deleted text when pasting
    map("x", "<leader>p", '"_dP')

    -- delete to void register
    map({ "n", "v" }, "<leader>d", '"_d', "Delete to void register")

    -- never press Q
    map("n", "Q", "<nop>")

    -- Redo remap
    map("n", "U", "<C-r>", "Redo")

    -- clear highlight
    map({ "i", "n" }, "<ESC>", "<CMD>noh<CR><ESC>", "Clear highlights")

    -- map Esc to C-c in command mode
    map("c", "<ESC>", "<C-c>")

    -- Remap for dealing with visual line wraps
    expmap("n", "k", "v:count == 0 ? 'gk' : 'k'", "Up (wrapped)")
    expmap("n", "j", "v:count == 0 ? 'gj' : 'j'", "Down (wrapped)")

    -- reselect visual block after indent/outdent
    map("v", "<", "<gv", "Indent Left")
    map("v", ">", ">gv", "Indent Right")

    -- paste over currently selected text without yanking it
    map("v", "p", '"_dp', "Paste (no yank)")
    map("v", "P", '"_dP', "Paste Before (no yank)")

    -- Copy everything between { and } including the brackets
    map("n", "YY", "va{Vy", "Yank Block {}")

    -- Exit on jj and jk
    map("i", "jj", "<ESC>", "Exit Insert")
    map("i", "jk", "<ESC>", "Exit Insert")

    -- Keep search results centered
    map("n", "n", "nzz", "Next Match (centered)")
    map("n", "N", "Nzz", "Prev Match (centered)")
    map("n", "*", "*zz", "Search Word (centered)")
    map("n", "#", "#zz", "Search Word Back (centered)")
    map("n", "g*", "g*zz", "Search Partial (centered)")
    map("n", "g#", "g#zz", "Search Partial Back (centered)")

    -- Split line with X
    nosmap("n", "X", ":keeppatterns substitute/\\s*\\%#\\s*/\\r/e <bar> normal! ==^<CR>", "Split Line")

    -- Write file in current directory (:w %:h/<new-file-name>)
    nosmap("n", "<C-n>", ":w %:h/", "Write New File")

    -- open new line in insert mode
    map("i", "<C-o><C-o>", "<C-o>o", "Open new line below")

    map("n", "<leader>z", function()
      MiniMisc.zoom()
    end, "Toggle zoom")

    -- splits
    map("n", "--", "<CMD>split<CR>", "Split window horizontally")
    map("n", "\\\\", "<CMD>vsplit<CR>", "Split window vertically")
    map("n", "<C-w>f", "<C-w>vgf", "Split window vertically and edit file name under the cursor")
    map("n", "<C-w><C-f>", "<C-w>vgf", "Split window vertically and edit file name under the cursor")

    -- makefile targets
    map("n", "<leader>mb", "<CMD>make build<CR>", "Make build")
    map("n", "<leader>mB", function()
      vim.cmd("make build ENTRYPOINT=" .. vim.fn.expand("%:p:."))
    end, "Make build current file")
    map("n", "<leader>mc", "<CMD>make clean<CR>", "Make clean")
    map("n", "<leader>mr", "<CMD>!make run<CR>", "Make run")
    map("n", "<leader>mR", function()
      vim.cmd("!make run ENTRYPOINT=" .. vim.fn.expand("%:p:."))
    end, "Make run current file")
    map("n", "<leader>md", "<CMD>make! debug<CR>", "Make debug")
    map("n", "<leader>mD", function()
      vim.cmd("!make debug ENTRYPOINT=" .. vim.fn.expand("%:p:."))
    end, "Make debug current file")

    -- file browser
    map("n", "<leader>o", "<CMD>Oil<CR>", "Filebrowser (Oil)")
    map("n", "<leader>e", function()
      Snacks.explorer()
    end, "Filebrowser (Snacks)")

    local picker = Snacks.picker

    -- buffers
    function find_buffers()
      picker.buffers({
        win = {
          input = { keys = { ["dd"] = "bufdelete", ["<c-d>"] = { "bufdelete", mode = { "n", "i" } } } },
          list = { keys = { ["dd"] = "bufdelete" } },
        },
      })
    end
    map("n", "<leader>bb", find_buffers, "Search buffers")
    map("n", "<leader>bd", function()
      MiniBufremove.delete()
    end, "Delete buffer")
    map("n", "<leader>bo", function()
      local buf = vim.api.nvim_get_current_buf()
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if b ~= buf and vim.bo[b].buflisted then
          MiniBufremove.delete(b)
        end
      end
    end, "Delete other buffers")
    map("n", "<leader>bs", picker.grep_buffers, "Search in open buffers")
    map("n", "<leader>.", function()
      Snacks.scratch()
    end, "Toogle scratch buffer")
    map("n", "<leader>br", function()
      Snacks.scratch.select()
    end, "List scratch buffers")

    -- tabs
    map("n", "<leader><tab>l", "<CMD>tablast<CR>", "Last tab")
    map("n", "<leader><tab>f", "<CMD>tabfirst<CR>", "First tab")
    map("n", "<leader><tab>]", "<CMD>tabnext<CR>", "Next tab")
    map("n", "<leader><tab>[", "<CMD>tabprevious<CR>", "Previous tab")
    map("n", "<leader><tab>o", "<CMD>tabonly<CR>", "Close other tabs")
    map("n", "<leader><tab><tab>", "<CMD>tabnew<CR>", "New tab")
    map("n", "<leader><tab>c", "<CMD>tabclose<CR>", "Close tab")

    -- Top Pickers
    map("n", "<leader><space>", picker.smart, "Smart Find Files")
    map("n", "<leader>,", find_buffers, "Buffers")
    map("n", "<leader>/", picker.grep, "Grep")
    map("n", "<leader>:", picker.command_history, "Command History")
    map("n", "<leader>n", picker.notifications, "Notification History")

    -- find
    map("n", "<leader>fb", find_buffers, "Find buffers")
    map("n", "<leader>ff", picker.files, "Find files")
    map("n", "<leader>fg", picker.git_files, "Find Git files")
    map("n", "<leader>fp", picker.projects, "Find projects")
    map("n", "<leader>fr", function()
      picker.recent({ filter = { paths = { [vim.fn.getcwd(0)] = true } } })
    end, "Find recent files")
    map("n", "<leader>fc", function()
      picker.files({ cwd = vim.fn.expand("%:p:h") })
    end, "Find files relative to current file")

    -- git
    map("n", "<leader>gg", function()
      Snacks.lazygit()
    end, "Lazygit")
    map("n", "<leader>gb", picker.git_branches, "Git branches")
    map("n", "<leader>gl", picker.git_log, "Git log")
    map("n", "<leader>gL", picker.git_log_line, "Git log line")
    map("n", "<leader>gs", picker.git_status, "Git status")
    map("n", "<leader>gS", picker.git_stash, "Git stash")
    map("n", "<leader>gd", picker.git_diff, "Git diff (hunks)")
    map("n", "<leader>gf", picker.git_log_file, "Git log file")

    -- grep
    map("n", "<leader>sb", picker.lines, "Buffer lines")
    map("n", "<leader>sB", find_buffers, "Grep open buffers")
    map("n", "<leader>sg", picker.grep, "Grep")
    map({ "n", "x" }, "<leader>sw", picker.grep_word, "Search word or visual selection")

    -- search
    map("n", '<leader>s"', picker.registers, "Search registers")
    map("n", "<leader>s/", picker.search_history, "Search history")
    map("n", "<leader>sc", picker.command_history, "Search command history")
    map("n", "<leader>sC", picker.commands, "Search commands")
    map("n", "<leader>sd", picker.diagnostics, "Search diagnostics")
    map("n", "<leader>sD", picker.diagnostics_buffer, "Search buffer diagnostics")
    map("n", "<leader>sh", picker.help, "Search help pages")
    map("n", "<leader>sH", picker.highlights, "Search highlights")
    map("n", "<leader>si", picker.icons, "Search icons")
    map("n", "<leader>sj", picker.jumps, "Search jumps")
    map("n", "<leader>sk", function()
      picker.keymaps({ layout = "select" })
    end, "Search keymaps")
    map("n", "<leader>sl", picker.loclist, "Search location list")
    map("n", "<leader>sm", picker.marks, "Search marks")
    map("n", "<leader>sp", picker.man, "Search man pages")
    map("n", "<leader>sq", picker.qflist, "Search quickfix list")
    map("n", "<leader>sR", picker.resume, "Resume picker")
    map("n", "<leader>su", picker.undo, "Search undo history")

    -- lsp
    map("n", "<leader>li", "<CMD>LspInfo<CR>", "LSP Info")
    map("n", "<leader>ll", "<CMD>LspLog<CR>", "LSP Log")
    map({ "n", "v", "x" }, "=", "<CMD>Format<CR>", "Format current buffer")
    map("n", "<leader>ls", picker.lsp_symbols, "Document symbols")
    map("n", "<leader>lS", picker.lsp_workspace_symbols, "Workspace symbols")

    -- terminal
    map("n", "<leader>tt", function()
      Snacks.terminal()
    end, "Terminal")
    map("n", "<leader>tc", function()
      Snacks.terminal(nil, { cwd = vim.fn.expand("%:p:h") })
    end, "Terminal in current folder")

    -- copilot
    map("n", "<leader>ce", "<CMD>Copilot enable<CR>", "Enable Copilot")
    map("n", "<leader>cd", "<CMD>Copilot disable<CR>", "Disable Copilot")
    map("n", "<leader>cs", "<CMD>Copilot status<CR>", "Show Copilot status")
  '';
}
