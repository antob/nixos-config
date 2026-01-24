{ ... }:
{
  programs.neovim.initLua = /* lua */ ''
    -- open filepicker on start
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argv(0) == "" then
          vim.defer_fn(function()
            Snacks.picker.files()
          end, 10)
        end
      end,
    })

    -- highlight when yanking text
    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        vim.highlight.on_yank()
      end,
    })

    -- close some filetypes with <q>
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("close_with_q", { clear = true }),
      pattern = {
        "help",
        "lspinfo",
        "man",
        "notify",
        "qf",
        "checkhealth",
      },
      callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
      end,
    })

    -- Resize neovim split when terminal is resized
    vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        vim.cmd("wincmd =")
      end,
    })

    -- Register dotenv ft as bash for TS highlighting
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "dotenv" },
      callback = function()
        vim.treesitter.language.register("bash", "dotenv")
      end,
    })

    -- Register tmux ft as bash for TS highlighting
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "tmux" },
      callback = function()
        vim.treesitter.language.register("config", "tmux")
      end,
    })

    -- Enable cursorline only in active window
    local cl_var = "auto_cursorline"
    vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained" }, {
      group = vim.api.nvim_create_augroup("enable_auto_cursorline", { clear = true }),
      callback = function()
        local ok, cl = pcall(vim.api.nvim_win_get_var, 0, cl_var)
        if ok and cl then
          vim.api.nvim_win_del_var(0, cl_var)
          vim.o.cursorline = true
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
      group = vim.api.nvim_create_augroup("disable_auto_cursorline", { clear = true }),
      callback = function()
        local cl = vim.o.cursorline
        if cl then
          vim.api.nvim_win_set_var(0, cl_var, cl)
          vim.o.cursorline = false
        end
      end,
    })
  '';
}
