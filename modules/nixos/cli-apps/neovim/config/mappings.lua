-- ## Keymappings
local map = vim.keymap.set

-- Misc --

-- Center buffer after C-u/d
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Reselect visual block after indent/outdent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move up/down on VISUAL line instead of a ACTUAL line
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

map("i", "jk", "<CMD>noh<CR><ESC>", { desc = "Normal mode and clear highlight" })
map({ "i", "n" }, "<ESC>", "<CMD>noh<CR><ESC>", { desc = "Normal mode and clear highlight" })

-- Telescope
map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "telescope find keymaps" })
