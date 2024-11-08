return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, conf)
    conf.defaults.mappings.i = {
        ["<Esc>"] = require("telescope.actions").close,
    }
    return conf
    end,
  },

  { "folke/which-key.nvim", lazy = false },

  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    }
  },
  {  "preservim/tagbar", lazy = false },
}
