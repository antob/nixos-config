{ pkgs, config, lib, ... }:

with lib;
let cfg = config.antob.cli-apps.neovim;

in {
  antob.home.extraOptions.programs.neovim.extraLuaConfig = mkIf cfg.enable ''
    -- Keymaps for better default experience
    -- See `:help vim.keymap.set()`
    vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
    vim.keymap.set("n", "<C-d>", "<C-d>zz")
    vim.keymap.set("n", "<C-u>", "<C-u>zz")
    vim.keymap.set("n", "<C-q>", "<cmd>qa<cr>", { desc = 'Quit all' })
    vim.keymap.set("n", "<C-c>", "<cmd>close<cr>", { desc = 'Close window' })
    vim.keymap.set("n", "<leader>c", "<cmd>bd<cr>", { desc = 'Close buffer' })
    vim.keymap.set("n", "\\", "<cmd>vsplit<cr>", { desc = 'Vertical split' })
    vim.keymap.set("n", "|", "<cmd>split<cr>", { desc = 'Horizontal split' })

    vim.keymap.set('n', '<leader>fn', "<cmd>enew<cr>", { desc = 'New File' })
    vim.keymap.set('n', 'gn', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
    vim.keymap.set('n', ']b', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
    vim.keymap.set('n', 'gp', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
    vim.keymap.set('n', '[b', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
    vim.keymap.set("n", "<C-Tab>", "<C-^>", { desc = 'Switch to Other buffer' })

    -- Reselect visual block after indent/outdent
    vim.keymap.set("v", "<", "<gv")
    vim.keymap.set("v", ">", ">gv")

    -- Remap for dealing with word wrap
    vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
    vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

    -- Navigate vim panes better
    vim.keymap.set('n', '<c-k>', ':wincmd k<CR>', { desc = 'Go to upper window' })
    vim.keymap.set('n', '<c-j>', ':wincmd j<CR>', { desc = 'Go to lower window' })
    vim.keymap.set('n', '<c-h>', ':wincmd h<CR>', { desc = 'Go to left window' })
    vim.keymap.set('n', '<c-l>', ':wincmd l<CR>', { desc = 'Go to right window' })
    vim.keymap.set('n', '<c-pagedown>', ':wincmd w<CR>', { desc = 'Go to next window' })
  '';
}
