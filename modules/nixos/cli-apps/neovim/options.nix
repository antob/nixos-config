{
  globals = {
    localleader = " ";
    mapleader = " ";
    markdown_folding = true;
  };

  opts = {
    laststatus = 3;
    showmode = false;

    clipboard = "unnamedplus";
    cursorline = true;
    cursorlineopt = "number";

    # Indenting
    expandtab = true;
    shiftwidth = 2;
    smartindent = true;
    tabstop = 2;
    softtabstop = 2;

    ignorecase = true;
    smartcase = true;
    mouse = "a";

    # Numbers
    number = true;
    relativenumber = true;
    numberwidth = 2;
    ruler = false;

    # Max number of entries in popups
    pumheight = 20;

    signcolumn = "yes";
    splitbelow = true;
    splitright = true;
    timeoutlen = 400;

    # Undo and swap
    swapfile = false;
    undofile = true;
    undolevels = 10000;
    backup = false;

    # interval for writing swap file to disk, also used by gitsigns
    updatetime = 250;

    # Search highlight
    hlsearch = false;
    incsearch = true;

    # Misc
    completeopt = "menu,menuone,noselect";
    wrap = false;
    termguicolors = true;
    scrolloff = 8;
  };

  diagnostics = {
    severity_sort = true;
    virtual_text = {
      prefix = "";
    };
    underline = true;
    float = {
      border = "solid";
    };
  };
}
