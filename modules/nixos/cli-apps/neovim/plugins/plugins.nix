{ pkgs, ... }:
{
  plugins = {
    indent-blankline = {
      enable = true;
      settings = {
        indent = {
          char = "│";
          # highlight = "IblChar";
        };
        scope = {
          char = "│";
          # highlight = "IblScopeChar";
        };
      };
    };

    transparent.enable = true;

    trouble.enable = true;

    gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
        current_line_blame_opts = {
          virt_text = true;
          virt_text_pos = "eol";
        };
        signcolumn = true;
        signs = {
          add = {
            text = "│";
          };
          change = {
            text = "│";
          };
          changedelete = {
            text = "󱕖";
          };
          delete = {
            text = "󰍵";
          };
          topdelete = {
            text = "‾";
          };
          untracked = {
            text = "┆";
          };
        };
        watch_gitdir = {
          follow_files = true;
        };
      };
    };

    lualine = {
      enable = true;
      settings = {
        options = {
          globalstatus = true;
          icons_enabled = true;
          theme = "onedark";
          component_separators = "|";
          section_separators = "";
        };
        sections = {
          lualine_c = [
            {
              __unkeyed-1 = "filename";
              path = 1;
            }
          ];
        };
      };
    };

    bufferline = {
      enable = true;
      settings = {
        options = {
          diagnostics = "nvim_lsp";
          offsets = [
            {
              filetype = "NvimTree";
              highlight = "Directory";
              text = "File Explorer";
              text_align = "center";
            }
          ];
        };
      };
    };

    comment.enable = true;
    nvim-autopairs.enable = true;
    nvim-colorizer.enable = true;
    render-markdown.enable = true;
    lazygit.enable = true;
    undotree.enable = true;
    fidget.enable = true;
    vim-surround.enable = true;

    which-key = {
      enable = true;
      settings = {
        spec = [
          # Settings groups
          {
            __unkeyed-1 = "<leader>g";
            group = "Git";
          }
          {
            __unkeyed-1 = "<leader><tab>";
            group = "Tabs";
          }
          {
            __unkeyed-1 = "<leader>f";
            group = "Find";
            icon = "";
          }
          {
            __unkeyed-1 = "<leader>b";
            group = "Buffer";
          }
          {
            __unkeyed-1 = "<leader>c";
            group = "Code Actions";
            icon = "";
          }
          {
            __unkeyed-1 = "<leader>d";
            group = "Diagnostics";
          }
          {
            __unkeyed-1 = "<leader>w";
            group = "Workspace";
          }
          {
            __unkeyed-1 = "<leader>m";
            group = "Marks";
          }

          # Keys with custom icons / labels
          {
            __unkeyed-1 = "<leader>fw";
            icon = "";
            desc = "Live Grep";
          }
        ];
      };
    };
  };

  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "my-plugin";
      src = pkgs.fetchFromGitHub {
        owner = "tpope";
        repo = "vim-rails";
        rev = "v5.4";
        hash = "sha256-oP5S6Z27Iv4Eu4694ZVC+U3Km3FJGUsiGFJ1ZpoXB1I=";
      };
    })
  ];
}
