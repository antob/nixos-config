{
  colorschemes = {
    tokyonight = {
      enable = false;
      settings = {
        style = "night";
        on_highlights = ''
          function(hl, c)
            -- Indent Blankline
            --hl.IndentBlanklineChar = { fg = c.bg_highlight, nocombine = true }
            hl.IndentBlanklineContextChar = { fg = c.comment }
            --hl.IblIndent = { fg = c.bg_highlight, nocombine = true }
            hl.IblScope = { fg = c.comment }

            -- CursorLine
            hl.CursorLine = { bg = "#292e42" }
            hl.CursorLineNr = { bold = true, fg = "#ff9e64"}

            -- Telescope
            local prompt = "#2d3149"
            hl.TelescopeSelection = {
              bg = prompt,
            }
            hl.TelescopeNormal = {
              bg = c.bg_dark,
              fg = c.fg_dark,
            }
            hl.TelescopeBorder = {
              bg = c.bg_dark,
              fg = c.bg_dark,
            }
            hl.TelescopePromptNormal = {
              bg = prompt,
            }
            hl.TelescopePromptBorder = {
              bg = prompt,
              fg = prompt,
            }
            hl.TelescopePromptTitle = {
              bg = prompt,
              fg = prompt,
            }
            hl.TelescopePreviewTitle = {
              bg = c.bg_dark,
              fg = c.bg_dark,
            }
            hl.TelescopeResultsTitle = {
              bg = c.bg_dark,
              fg = c.bg_dark,
            }
          end
        '';
      };
    };

    catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
        integrations = {
          cmp = true;
          gitsigns = true;
          notify = true;
          nvimtree = true;
          treesitter = true;
          telescope = true;
          which_key = true;
          indent_blankline = {
            enabled = true;
            scope_color = "surface2";
          };
          snacks = true;
          lsp_trouble = true;
          copilot_vim = true;
          native_lsp.enabled = true;
        };
        custom_highlights = ''
          function(c)
            return {
              -- Telescope
              TelescopeSelection = { bg = c.surface0 },
              TelescopeNormal = { bg = c.base, fg = c.subtext0 },
              TelescopeBorder = { bg = c.base, fg = c.base },
              TelescopePromptNormal = { bg = c.base },
              TelescopePromptBorder = { bg = c.base, fg = c.base },
              TelescopePromptTitle = { bg = c.base, fg = c.base },
              TelescopePreviewTitle = { bg = c.base, fg = c.base },
              TelescopeResultsTitle = { bg = c.base, fg = c.base },

              -- CursorLine
              CursorLine = { bg = c.base },

              -- Floating windows
              FloatBorder = { fg = c.surface0 },
            }
          end
        '';
      };
    };
  };
}
