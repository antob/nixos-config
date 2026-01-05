{ ... }:
{
  programs.neovim.extraLuaConfig = /* lua */ ''
    -- center buffer after ctrl u/d
    map("n", "<C-d>", "<C-d>zz")
    map("n", "<C-u>", "<C-u>zz")

    -- use ; to enter command mode
    nosmap({ "n", "v", "x" }, ";", ":")
    nosmap({ "n", "v", "x" }, ":", ";")

    -- yank to system clipboard
    map({ "v", "x", "n" }, "<C-y>", '"+y', "Yank to System clipboard.")
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

    -- Move selected line / block of text in visual mode
    map("v", "J", ":m '>+1<CR>gv=gv", "Move Lines Down")
    map("v", "K", ":m '<-2<CR>gv=gv", "Move Lines Up")

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

    -- Panes resizing
    map("n", "+", ":vertical resize +5<CR>", "Increase Width")
    map("n", "_", ":vertical resize -5<CR>", "Decrease Width")

    -- Keep search results centered
    map("n", "n", "nzzzv", "Next Match (centered)")
    map("n", "N", "Nzzzv", "Prev Match (centered)")
    map("n", "*", "*zzv", "Search Word (centered)")
    map("n", "#", "#zzv", "Search Word Back (centered)")
    map("n", "g*", "g*zz", "Search Partial (centered)")
    map("n", "g#", "g#zz", "Search Partial Back (centered)")

    -- Split line with X
    nosmap("n", "X", ":keeppatterns substitute/\\s*\\%#\\s*/\\r/e <bar> normal! ==^<CR>", "Split Line")

    -- ctrl + x to cut full line
    map("n", "<C-x>", "dd", "Cut Line")

    -- Select all
    map("n", "<C-a>", "ggVG", "Select All")

    -- Write file in current directory (:w %:h/<new-file-name>)
    nosmap("n", "<C-n>", ":w %:h/", "Write New File")

    -- open new line in insert mode
    map("i", "<C-o>", "<ESC>o", "Open new line below")
    map("i", "<C-S-o>", "<ESC><S-o>", "Open new line above")

    -- navigation
    map("i", "<C-b>", "<ESC>^i", "Move to beginning of line")
    map("i", "<C-e>", "<End>", "Move to end of line")
    map("n", "<C-h>", "<C-w>h", "Focus window left")
    map("n", "<C-l>", "<C-w>l", "Focus window right")
    map("n", "<C-j>", "<C-w>j", "Focus window down")
    map("n", "<C-k>", "<C-w>k", "Focus window up")
    map("n", "<C-m>", function()
      Snacks.zen.zoom()
    end, "Toggle zoom")

    -- save file
    nosmap("n", "<C-s>", "<CMD>w<CR>", "Save file")

    -- copy whole file
    map("n", "<C-c>", "<CMD>%y+<CR>", "Copy whole file")

    -- splits
    map("n", "--", "<CMD>split<CR>", "Split window horizontally")
    map("n", "\\\\", "<CMD>vsplit<CR>", "Split window vertically")

    -- makefile targets
    map("n", "<leader>mb", "<CMD>make build<CR>", "Make build")
    map("n", "<leader>mB", function()
      vim.cmd.make("build NAME=" .. vim.fn.expand("%:t:r") .. " SRCFILE=" .. vim.fn.expand("%:."))
    end, "Make build current file")
    map("n", "<leader>mc", "<CMD>make clean<CR>", "Make clean")
    map("n", "<leader>mr", "<CMD>make run<CR>", "Make run")
    map("n", "<leader>mR", function()
      vim.cmd.make("run NAME=" .. vim.fn.expand("%:t:r") .. " SRCFILE=" .. vim.fn.expand("%:."))
    end, "Make run current file")
    map("n", "<leader>md", "<CMD>make debug<CR>", "Make debug")
    map("n", "<leader>mD", function()
      vim.cmd.make("debug NAME=" .. vim.fn.expand("%:t:r") .. " SRCFILE=" .. vim.fn.expand("%:."))
    end, "Make debug current file")

    -- file browser
    map("n", "<leader>o", "<CMD>Oil<CR>", "Filebrowser (Oil)")
    map("n", "<leader>e", function()
      Snacks.explorer()
    end, "Filebrowser (Snacks)")

    -- buffers
    function find_buffers()
      Snacks.picker.buffers({
        win = {
          input = { keys = { ["dd"] = "bufdelete", ["<c-d>"] = { "bufdelete", mode = { "n", "i" } } } },
          list = { keys = { ["dd"] = "bufdelete" } },
        },
      })
    end
    map({ "n", "i", "v" }, "<S-Left>", "<CMD>bprevious<CR>", "Previous buffer")
    map({ "n", "i", "v" }, "<S-Right>", "<CMD>bnext<CR>", "Next buffer")
    map({ "n", "i", "v" }, "<S-Up>", "<CMD>e #<CR>", "Switch to other buffer")
    map({ "n", "i", "v" }, "<S-Down>", find_buffers, "Search buffers")
    map("n", "<leader>bb", find_buffers, "Search buffers")
    map("n", "<leader>bd", function()
      Snacks.bufdelete()
    end, "Delete buffer")
    map("n", "<leader>bo", function()
      Snacks.bufdelete.other()
    end, "Delete other buffers")
    map("n", "<leader>bs", function()
      Snacks.picker.grep_buffers()
    end, "Search in open buffers")

    -- tabs
    map("n", "<leader><tab>l", "<CMD>tablast<CR>", "Last tab")
    map("n", "<leader><tab>f", "<CMD>tabfirst<CR>", "First tab")
    map("n", "<leader><tab>]", "<CMD>tabnext<CR>", "Next tab")
    map("n", "<leader><tab>[", "<CMD>tabprevious<CR>", "Previous tab")
    map("n", "<leader><tab>o", "<CMD>tabonly<CR>", "Close other tabs")
    map("n", "<leader><tab><tab>", "<CMD>tabnew<CR>", "New tab")
    map("n", "<leader><tab>c", "<CMD>tabclose<CR>", "Close tab")

    -- find
    map("n", "<leader>ff", function()
      Snacks.picker.files()
    end, "Find files")
    map("n", "<C-p>", function()
      Snacks.picker.files()
    end, "Find files")
    map("n", "<leader>fo", function()
      Snacks.picker.recent({ filter = { paths = { [vim.fn.getcwd(0)] = true } } })
    end, "Find old files")
    map("n", "<leader>fr", function()
      Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") })
    end, "Find files relative to buffer")
    map("n", "<leader>fl", function()
      Snacks.picker.resume()
    end, "Open last picker")
    map("n", "<leader>fp", function()
      Snacks.picker.projects()
    end, "Find projects")

    -- search
    map("n", "<leader>ss", function()
      Snacks.picker.grep()
    end, "Grep")
    map("n", "<leader>sw", function()
      Snacks.picker.grep_word()
    end, "Search word under cursor")
    map("n", "<leader>sh", function()
      Snacks.picker.help()
    end, "Search help pages")
    map("n", "<leader>sm", function()
      Snacks.picker.man()
    end, "Search man pages")
    map("n", "<leader>sk", function()
      Snacks.picker.keymaps({ layout = "select" })
    end, "Search keymaps")

    -- git
    map("n", "<leader>gg", function()
      Snacks.lazygit()
    end, "Lazygit")
    map("n", "<leader>gs", function()
      Snacks.picker.git_status()
    end, "Git status")
    map("n", "<leader>gd", function()
      Snacks.picker.git_diff()
    end, "Git diff")
    map("n", "<leader>gl", function()
      Snacks.picker.git_log()
    end, "Git commits")
    map("n", "<leader>gf", function()
      Snacks.picker.git_log_file()
    end, "Current file git commits")

    -- lsp
    map("n", "<leader>li", "<CMD>LspInfo<CR>", "LSP Info")
    map("n", "<leader>ll", "<CMD>LspLog<CR>", "LSP Log")
    map({ "n", "v", "x" }, "=", "<CMD>Format<CR>", "Format current buffer")
    map("n", "<leader>ls", function()
      Snacks.picker.lsp_symbols()
    end, "Document symbols")
    map("n", "<leader>lS", function()
      Snacks.picker.lsp_workspace_symbols()
    end, "Workspace symbols")
    map("n", "gd", function()
      Snacks.picker.lsp_definitions()
    end, "LSP definitions")
    map("n", "gr", function()
      Snacks.picker.lsp_references()
    end, "LSP references")
    map("n", "gI", function()
      Snacks.picker.lsp_implementations()
    end, "LSP implementations")

    -- diagnostics
    map("n", "<leader>dd", function()
      Snacks.picker.diagnostics()
    end, "Workspace diagnostics")

    -- terminal
    map("n", "<leader>tt", function()
      Snacks.terminal()
    end, "Terminal")
    map("n", "<leader>tc", function()
      Snacks.terminal(nil, { cwd = vim.fn.expand("%:p:h") })
    end, "Terminal in current folder")
  '';
}
