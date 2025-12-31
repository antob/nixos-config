{ ... }:
{
  programs.neovim.extraLuaConfig = /* lua */ ''
    -- open filepicker on start
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argv(0) == "" then
          vim.defer_fn(function()
            Snacks.picker.recent({ filter = { paths = { [vim.fn.getcwd(0)] = true } } })
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
  '';
}
