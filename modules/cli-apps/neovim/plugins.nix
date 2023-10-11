{ pkgs, config, lib, ... }:

with lib;
let cfg = config.antob.cli-apps.neovim;

in {
  antob.home.extraOptions.programs.neovim.plugins = with pkgs.vimPlugins;
    mkIf cfg.enable [
      {
        plugin = onedark-nvim;
        type = "lua";
        config = # lua
          ''
            require('onedark').setup {
              transparent = true
            }
            require('onedark').load()
          '';
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = # lua
          ''
            require('lualine').setup {
              options = {
                  icons_enabled = true,
                  theme = 'onedark',
                  component_separators = '|',
                  section_separators = "",
              },
              sections = {
                lualine_c = { { 'filename', path = 1 } },
              },
            }
          '';
      }
      {
        plugin = which-key-nvim;
        type = "lua";
        config = # lua
          ''
            require('which-key').setup{}
          '';
      }
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = # lua
          ''
            require('indent_blankline').setup {
              show_trailing_blankline_indent = false
            }
            vim.cmd [[highlight IndentBlanklineChar guifg=#3b3f4c gui=nocombine]]
          '';
      }
      {
        plugin = nvim-web-devicons;
        type = "lua";
        config = # lua
          ''
            require('nvim-web-devicons').setup{}
          '';
      }
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = # lua
          ''
            require('gitsigns').setup{
              -- signs = {
              --   add = { text = '+' },
              --   change = { text = '~' },
              --   delete = { text = '_' },
              --   topdelete = { text = '‾' },
              --   changedelete = { text = '~' },
              -- },
              on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                local function map(mode, l, r, opts)
                  opts = opts or {}
                  opts.buffer = bufnr
                  vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map('n', ']c', function()
                  if vim.wo.diff then return ']c' end
                  vim.schedule(function() gs.next_hunk() end)
                  return '<Ignore>'
                end, { expr = true, desc = 'Goto next change' })

                map('n', '[c', function()
                  if vim.wo.diff then return '[c' end
                  vim.schedule(function() gs.prev_hunk() end)
                  return '<Ignore>'
                end, { expr = true, desc = 'Goto prev change' })
              end
            }
          '';
      }
      {
        plugin = nvim-surround;
        type = "lua";
        config = ''
          require('nvim-surround').setup()
        '';
      }
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''
          require('Comment').setup()
        '';
      }
      vim-fugitive
      vim-nix
      vim-sleuth
      # catppuccin-nvim
    ];
}
