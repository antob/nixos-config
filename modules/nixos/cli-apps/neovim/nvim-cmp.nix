{ pkgs, config, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.cli-apps.neovim;

in {
  antob.home.extraOptions.programs.neovim.plugins = with pkgs.vimPlugins;
    mkIf cfg.enable [
      cmp-nvim-lsp
      luasnip
      cmp_luasnip
      friendly-snippets
      cmp-buffer
      {
        plugin = nvim-cmp;
        type = "lua";
        config = # lua
          ''
            local cmp = require 'cmp'
            local luasnip = require 'luasnip'

            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup {
                snippet = {
                    expand = function(args)
                      luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert {
                    ['<C-b>'] = cmp.mapping.scroll_docs( -4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<CR>'] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    },
                    ['<Tab>'] = cmp.mapping(function(fallback)
                      if cmp.visible() then
                        cmp.select_next_item()
                      elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                      else
                        fallback()
                      end
                    end, { 'i', 's' }),
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                      if cmp.visible() then
                        cmp.select_prev_item()
                      elseif luasnip.jumpable( -1) then
                        luasnip.jump( -1)
                      else
                        fallback()
                      end
                    end, { 'i', 's' }),
                },
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                },
            }
          '';
      }
    ];
}
