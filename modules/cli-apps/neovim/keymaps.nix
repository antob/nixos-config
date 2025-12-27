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

    -- Navigate buffers
    map("n", "<Right>", ":bnext<CR>", "Next Buffer")
    map("n", "<Left>", ":bprevious<CR>", "Prev Buffer")

    -- Panes resizing
    map("n", "+", ":vertical resize +5<CR>", "Increase Width")
    map("n", "_", ":vertical resize -5<CR>", "Decrease Width")

    -- Keep search results centered
    map("n", "n", "nzzv", "Next Match (centered)")
    map("n", "N", "Nzzv", "Prev Match (centered)")
    map("n", "*", "*zzv", "Search Word (centered)")
    map("n", "#", "#zzv", "Search Word Back (centered)")
    map("n", "g*", "g*zz", "Search Partial (centered)")
    map("n", "g#", "g#zz", "Search Partial Back (centered)")

    -- Split line with X
    map("n", "X", ":keeppatterns substitute/\\s*\\%#\\s*/\\r/e <bar> normal! ==^<cr>", "Split Line")

    -- ctrl + x to cut full line
    map("n", "<C-x>", "dd", "Cut Line")

    -- Select all
    map("n", "<C-a>", "ggVG", "Select All")

    -- Write file in current directory (:w %:h/<new-file-name>)
    map("n", "<C-n>", ":w %:h/", "Write New File")

    -- navigation
    map("i", "<C-b>", "<ESC>^i", "Move to beginning of line")
    map("i", "<C-e>", "<End>", "Move to end of line")
    map("n", "<C-h>", "<C-w>h", "Focus window left")
    map("n", "<C-l>", "<C-w>l", "Focus window right")
    map("n", "<C-j>", "<C-w>j", "Focus window down")
    map("n", "<C-k>", "<C-w>k", "Focus window up")

    -- save file
    map("n", "<C-s>", "<cmd>w<CR>", "Save file")

    -- copy whole file
    map("n", "<C-c>", "<cmd>%y+<CR>", "Copy whole file")

    -- splits
    map("n", "--", "<CMD>split<CR>", "Split window horizontally")
    map("n", "\\\\", "<CMD>vsplit<CR>", "Split window vertically")

    -- buffers
    map("n", "<S-h>", "<CMD>bprevious<CR>", "Previous buffer")
    map("n", "<S-l>", "<CMD>bnext<CR>", "Next buffer")
    map("n", "<leader>bb", "<CMD>e #<CR>", "Switch to other buffer")

    -- tabs
    map("n", "<leader><tab>l", "<CMD>tablast<CR>", "Last tab")
    map("n", "<leader><tab>f", "<CMD>tabfirst<CR>", "First tab")
    map("n", "<leader><tab>]", "<CMD>tabnext<CR>", "Next tab")
    map("n", "<leader><tab>[", "<CMD>tabprevious<CR>", "Previous tab")
    map("n", "<leader><tab>o", "<CMD>tabonly<CR>", "Close other tabs")
    map("n", "<leader><tab><tab>", "<CMD>tabnew<CR>", "New tab")
    map("n", "<leader><tab>c", "<CMD>tabclose<CR>", "Close tab")

    local builtin = require("telescope.builtin")
    local utils = require("telescope.utils")
    function all_files() builtin.find_files({ no_ignore = true, follow = true, hidden = true }) end
    function relative_files() builtin.find_files({ cwd = utils.buffer_dir() }) end

    -- find
    map("n", "<leader>ff", builtin.find_files, "Find files")
    map("n", "<C-p>", builtin.find_files, "Find files")
    map("n", "<leader>fa", all_files, "Find all files")
    map("n", "<leader>fo", builtin.oldfiles, "Find old files")
    map("n", "<leader>fr", relative_files, "Find files relative to buffer")
    map("n", "<leader>fl", builtin.resume, "Open last picker")

    -- search
    map("n", "<leader>ss", builtin.live_grep, "Grep")
    map("n", "<leader>sw", builtin.grep_string, "Search word under cursor")
    map("n", "<leader>sb", builtin.buffers, "Search buffers")
    map("n", "<leader>sc", builtin.current_buffer_fuzzy_find, "Search in current buffer")
    map("n", "<leader>sh", builtin.help_tags, "Search help pages")
    map("n", "<leader>sm", builtin.man_pages, "Search man pages")
    map("n", "<leader>sk", builtin.keymaps, "Search keymaps")

    -- git
    map("n", "<leader>gg", "<cmd>LazyGit<cr>", "Lazygit")
    map("n", "<leader>gs", builtin.git_status, "Git status")
    map("n", "<leader>gc", builtin.git_commits, "Git commits")
    map("n", "<leader>gf", builtin.git_bcommits, "Current file git commits")

    -- lsp
    map({ "n", "v", "x" }, "<leader>=", vim.lsp.buf.format, "Format current buffer")
    map("n", "<leader>li", "<cmd>LspInfo<cr>", "LSP Info")
    map("n", "<leader>lr", "<cmd>LspRestart<cr>", "LSP Restart")
    map("n", "<leader>lh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end, "Toggle Inlay Hints")
    map("n", "<leader>ls", builtin.lsp_document_symbols, "Document symbols")
    map("n", "<leader>lS", builtin.lsp_workspace_symbols, "Workspace symbols")

    map("n", "<leader>gd", builtin.lsp_definitions, "LSP definitions")
    map("n", "<leader>gr", builtin.lsp_references, "LSP references")
    map("n", "<leader>gi", builtin.lsp_implementations, "LSP implementations")

    -- telescope diagnistics
    map("n", "<leader>dd", builtin.diagnostics, "Find diagnostics")
  '';
}
