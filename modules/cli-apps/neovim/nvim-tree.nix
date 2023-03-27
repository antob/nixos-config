{ pkgs, config, lib, ... }:

with lib;
let cfg = config.antob.cli-apps.neovim;

in {
  antob.home.extraOptions.programs.neovim.plugins = with pkgs.vimPlugins;
    mkIf cfg.enable [{
      plugin = nvim-tree-lua;
      type = "lua";
      config = # lua
        ''
          require('nvim-tree').setup {
            view = {
                width = 35,
            },
            renderer = {
                group_empty = true,
            },
            filters = {
                dotfiles = true,
            },
            hijack_directories = {
              enable = true,
              auto_open = false,
            },
          }

          vim.api.nvim_set_keymap("n", "<C-b>", ":NvimTreeToggle<cr>", { silent = true, noremap = true, desc = 'Toggle NvimTree' })
        '';
    }];
}
