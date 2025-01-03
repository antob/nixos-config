let
  selectOpts = "{behavior = cmp.SelectBehavior.Select}";
in
{ lib, ... }:
{
  plugins = {
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        performance = {
          debounce = 150;
        };
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";

          "<Up>" = "cmp.mapping.select_prev_item(${selectOpts})";
          "<Down>" = "cmp.mapping.select_next_item(${selectOpts})";

          "<C-p>" = "cmp.mapping.select_prev_item(${selectOpts})";
          "<C-n>" = "cmp.mapping.select_next_item(${selectOpts})";

          "<C-u>" = "cmp.mapping.scroll_docs(-4)";
          "<C-d>" = "cmp.mapping.scroll_docs(4)";

          "<C-e>" = "cmp.mapping.abort()";
          "<C-y>" = "cmp.mapping.confirm({select = true})";
          # "<CR>" = "cmp.mapping.confirm({select = false})";
          "<CR>" = ''
            cmp.mapping(
              function(fallback)
                if cmp.visible() then
                  if require("luasnip").expandable() then
                    require("luasnip").expand()
                  else
                    cmp.confirm({
                        select = true,
                    })
                  end
                else
                  fallback()
                end
              end
            )
          '';

          "<Tab>" = ''
            cmp.mapping(
              function(fallback)
                local col = vim.fn.col('.') - 1

                if cmp.visible() then
                  cmp.select_next_item(select_opts)
                elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                  fallback()
                else
                  cmp.complete()
                end
              end,
              { "i", "s" }
            )
          '';

          "<S-Tab>" = ''
            cmp.mapping(
              function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item(select_opts)
                else
                  fallback()
                end
              end,
              { "i", "s" }
            )
          '';
        };
        window = {
          completion = {
            border = "solid";
            zindex = 1001;
            scrolloff = 0;
            colOffset = -3;
            sidePadding = 0;
            scrollbar = true;
          };
          documentation = {
            border = "solid";
            zindex = 1001;
            maxHeight = 20;
          };
        };

        sources = [
          {
            name = "nvim_lsp";
            # keywordLength = 1;
          }
          { name = "luasnip"; }
          {
            name = "buffer";
            # keywordLength = 3;
          }
          { name = "nvim_lua"; }
          { name = "path"; }
        ];

        # completion = {
        #  # completeopt = "menu,menuone";
        #   keywordLength = 1;
        # };
        snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
        formatting = {
          fields = [
            "kind"
            "abbr"
            "menu"
          ];
          format = lib.mkForce ''
            function(entry, item)
              local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, item)
              local strings = vim.split(kind.kind, "%s", { trimempty = true })
              kind.kind = " " .. (strings[1] or "") .. " "
              kind.menu = "    (" .. (strings[2] or "") .. ")"

              return kind
            end
          '';
          # format = ''
          #   require("lspkind").cmp_format({
          #     mode = "symbol_text",
          #     menu = ({
          #       buffer = "[BUF]",
          #       nvim_lsp = "[LSP]",
          #       luasnip = "[SNIP]",
          #       nvim_lua = "[LUA]",
          #     })
          #   }),
          # '';
          # format = ''
          #   function(entry, item)
          #     local menu_icon = {
          #       nvim_lsp = '[LSP]',
          #       luasnip = '[SNIP]',
          #       buffer = '[BUF]',
          #       path = '[PATH]',
          #     }

          #     item.menu = menu_icon[entry.source.name]
          #     return item
          #   end
          # '';
        };
      };
    };

    luasnip.enable = true;
    friendly-snippets.enable = true;
    lspkind = {
      enable = true;
      # cmp = {
      #   enable = false;
      #   # menu = {
      #   #   buffer = "[BUF]";
      #   #   nvim_lsp = "[LSP]";
      #   #   luasnip = "[SNIP]";
      #   #   nvim_lua = "[LUA]";
      #   # };
      # };
    };
  };
}
