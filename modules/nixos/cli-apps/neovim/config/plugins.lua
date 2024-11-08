-- ## Configure plugins

-- Lazygit Telescope extension
--require("telescope").load_extension("lazygit")

-- Which key
local wk = require("which-key")
wk.add({
  { "<leader>tt", "<cmd>TagbarToggle<cr>", desc = "Toggle Tagbar", mode = "n" },
})
