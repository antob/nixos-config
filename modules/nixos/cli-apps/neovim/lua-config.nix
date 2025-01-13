{
  extraConfigLua = ''
    -- add secret files as text filetype
    -- which will not be sent to Copilot
    vim.filetype.add({
      pattern = {
        ['%.env.*'] = { 'text', { priority = math.huge } },
      },
    })

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
