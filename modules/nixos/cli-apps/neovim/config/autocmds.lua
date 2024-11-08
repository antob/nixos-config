-- ## Autocmds
local autocmd = vim.api.nvim_create_autocmd

-- Open find files on Vim startup
autocmd({ "VimEnter"}, {
  callback = function()
    if vim.fn.argv(0) == '' then
      require('telescope.builtin').find_files()
    end
  end,
})
