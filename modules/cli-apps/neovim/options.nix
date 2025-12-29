{ lib, ... }:
{
  programs.neovim.extraLuaConfig = lib.mkOrder 200 /* lua */ ''
    -- globals
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "
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
    vim.opt.shortmess:append("sI")

    -- go to previous/next line with h,l,left arrow and right arrow
    -- when cursor reaches end/beginning of line
    vim.opt.whichwrap:append("<>[]hl")

    vim.opt.fillchars = { eob = " " }
  '';
}
