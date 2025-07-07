{ pkgs, ... }:
{
  plugins = {
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<A-o>";
            node_incremental = "<A-o>";
            scope_incremental = false; # "<A-up>"
            node_decremental = "<A-i>";
          };
        };
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        css
        embedded_template
        html
        javascript
        json
        lua
        markdown
        markdown_inline
        nix
        ruby
        rust
        typescript
        vim
        vimdoc
        xml
        yaml
      ];
    };
    treesitter-textobjects = {
      enable = true;
      select = {
        enable = true;
        lookahead = true;
        keymaps = {
          "a=" = {
            query = "@assignment.outer";
            desc = "Select outer part of an assignment";
          };
          "i=" = {
            query = "@assignment.inner";
            desc = "Select inner part of an assignment";
          };
          "l=" = {
            query = "@assignment.lhs";
            desc = "Select left hand side of an assignment";
          };
          "r=" = {
            query = "@assignment.rhs";
            desc = "Select right hand side of an assignment";
          };
          "aa" = {
            query = "@parameter.outer";
            desc = "Select outer part of a parameter/argument";
          };
          "ia" = {
            query = "@parameter.inner";
            desc = "Select inner part of a parameter/argument";
          };
          "af" = {
            query = "@function.outer";
            desc = "Select outer part of a method/function definition";
          };
          "if" = {
            query = "@function.inner";
            desc = "Select inner part of a method/function definition";
          };
          "ac" = {
            query = "@class.outer";
            desc = "Select outer part of a class";
          };
          "ic" = {
            query = "@class.inner";
            desc = "Select inner part of a class";
          };
        };
      };

      move = {
        enable = true;
        setJumps = true;
        gotoNextStart = {
          "]]" = {
            query = "@function.outer";
            desc = "Next method/function def start";
          };
          "]c" = {
            query = "@class.outer";
            desc = "Next class start";
          };
          "]a" = {
            query = "@parameter.outer";
            desc = "Next parameter start";
          };
        };
        gotoNextEnd = {
          "][" = {
            query = "@function.outer";
            desc = "Next method/function def end";
          };
          "]C" = {
            query = "@class.outer";
            desc = "Next class end";
          };
          "]A" = {
            query = "@parameter.outer";
            desc = "Next parameter end";
          };
        };
        gotoPreviousStart = {
          "[[" = {
            query = "@function.outer";
            desc = "Prev method/function def start";
          };
          "[c" = {
            query = "@class.outer";
            desc = "Prev class start";
          };
          "[a" = {
            query = "@parameter.outer";
            desc = "Prev parameter start";
          };
        };
        gotoPreviousEnd = {
          "[]" = {
            query = "@function.outer";
            desc = "Prev method/function def end";
          };
          "[C" = {
            query = "@class.outer";
            desc = "Prev class end";
          };
          "[A" = {
            query = "@parameter.outer";
            desc = "Prev parameter end";
          };
        };
      };
    };
  };
}
