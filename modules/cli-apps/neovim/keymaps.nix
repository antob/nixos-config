{ ... }:
{
  programs.neovim.extraLuaConfig = /* lua */ ''
    -- center buffer after ctrl u/d
    map("n", "<C-d>", "<C-d>zz")
    map("n", "<C-u>", "<C-u>zz")

    -- use ; to enter command mode
    map({ "n", "v", "x" }, ";", ":")
    map({ "n", "v", "x" }, ":", ";")

    -- yank to system clipboard
    map({ "v", "x", "n" }, "<C-y>", '"+y', "Yank to System clipboard.")
    map({ "v", "x", "n" }, "<leader>y", '"+y', "Yank to System clipboard.")

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
    map({ "n", "v" }, "<leader>d", '"_d', "Delete to void register")

    -- never press Q
    map("n", "Q", "<nop>")

    -- clear highlight
    map({ "i", "n" }, "<ESC>", "<CMD>noh<CR><ESC>", "Clear highlights")

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
  '';
}
