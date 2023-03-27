{ pkgs, config, lib, ... }:

with lib;
let cfg = config.antob.cli-apps.neovim;

in {
  antob.home.extraOptions.programs.neovim.plugins = with pkgs.vimPlugins;
    mkIf cfg.enable [
      {
        plugin = nvim-treesitter.withPlugins (p: [
          p.c
          p.cpp
          p.ruby
          p.lua
          p.python
          p.rust
          p.typescript
          p.help
          p.vim
          p.nix
        ]);
        type = "lua";
        config = # lua
          ''
            require('nvim-treesitter.configs').setup {
              highlight = { enable = true },
              indent = { enable = true, disable = { 'python' } },
              incremental_selection = {
                enable = true,
                keymaps = {
                  init_selection = '<a-o>',
                  node_incremental = '<a-o>',
                  scope_incremental = '<a-up>',
                  node_decremental = '<a-i>',
                },
              },
              textobjects = {
                select = {
                  enable = true,
                  lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                  keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ['aa'] = '@parameter.outer',
                    ['ia'] = '@parameter.inner',
                    ['af'] = '@function.outer',
                    ['if'] = '@function.inner',
                    ['ac'] = '@class.outer',
                    ['ic'] = '@class.inner',
                  },
                },
                move = {
                  enable = true,
                  set_jumps = true, -- whether to set jumps in the jumplist
                  goto_next_start = {
                    [']f'] = '@function.outer',
                    [']a'] = '@parameter.outer',
                    [']]'] = '@class.outer',
                  },
                  goto_next_end = {
                    [']F'] = '@function.outer',
                    [']A'] = '@parameter.outer',
                    [']['] = '@class.outer',
                  },
                  goto_previous_start = {
                    ['[f'] = '@function.outer',
                    ['[a'] = '@parameter.outer',
                    ['[['] = '@class.outer',
                  },
                  goto_previous_end = {
                    ['[F'] = '@function.outer',
                    ['[A'] = '@parameter.outer',
                    ['[]'] = '@class.outer',
                  },
                },
                swap = {
                  enable = true,
                  swap_next = {
                    ['<leader>a'] = '@parameter.inner',
                  },
                  swap_previous = {
                    ['<leader>A'] = '@parameter.inner',
                  },
                },
              },
            }
          '';
      }
      nvim-treesitter-textobjects
    ];
}
