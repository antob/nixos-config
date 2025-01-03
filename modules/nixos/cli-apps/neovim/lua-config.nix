{
  extraConfigLua = ''
    -- disable nvim intro
    vim.opt.shortmess:append "sI"

    -- go to previous/next line with h,l,left arrow and right arrow
    -- when cursor reaches end/beginning of line
    vim.opt.whichwrap:append "<>[]hl"

    vim.opt.fillchars = { eob = " " }

    -- UndoTree config
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_SplitWidth = 40

    -- Copilot kemaps
    vim.api.nvim_set_keymap('i', '<Right>', 'copilot#Accept("<Right>")', { expr=true, noremap = true, silent = true })
  '';
}
