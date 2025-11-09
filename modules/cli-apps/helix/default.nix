{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.helix;
in
{
  options.antob.cli-apps.helix = with types; {
    enable = mkEnableOption "Whether or not to enable helix.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.helix = {
        enable = true;
        settings = {
          theme = "catppuccin_mocha";

          editor = {
            line-number = "relative";
            mouse = false;
            cursorline = true;
            bufferline = "multiple";
            auto-format = true;
            color-modes = true;
            # Sync clipboard with system clipboard
            default-yank-register = "+";

            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };

            statusline.right = [
              "diagnostics"
              "selections"
              "position"
              "position-percentage"
              "file-encoding"
            ];

            lsp = {
              display-progress-messages = true;
              display-inlay-hints = true;
            };

            file-picker.hidden = false;

            whitespace.render = {
              space = "none";
              tab = "all";
              newline = "none";
            };

            indent-guides = {
              render = true;
              # character = "╎";
            };
          };

          keys = {
            normal = {
              C-q = ":qa";
              C-u = [
                "half_page_up"
                "goto_window_center"
              ];
              C-d = [
                "half_page_down"
                "goto_window_center"
              ];
              C-g = [
                ":new"
                ":insert-output lazygit"
                ":buffer-close!"
                ":redraw"
              ];
              "A-[" = "goto_previous_buffer";
              "A-]" = "goto_next_buffer";
              A-w = ":buffer-close";
              X = [
                "extend_line_up"
                "extend_to_line_bounds"
              ];
              space = {
                c = "file_picker_in_current_buffer_directory";
              };
              "^" = "goto_first_nonwhitespace";
              "0" = "goto_line_start";
              "$" = "goto_line_end";
            };

            insert = {
              j = {
                k = "normal_mode";
              };
            };

            select = {
              y = [
                ":clipboard-yank"
                "yank"
              ];
              X = [
                "extend_line_up"
                "extend_to_line_bounds"
              ];
              "^" = "goto_first_nonwhitespace";
              "0" = "goto_line_start";
              "$" = "goto_line_end";
            };
          };
        };

        languages = {
          language-server = {
            solargraph = {
              diagnostics = true;
              formatting = true;
            };
            ruby-lsp = {
              command = "ruby-lsp";
            };
          };

          language = [
            {
              name = "ruby";
              auto-format = true;
              formatter = {
                command = "standardrb";
                args = [
                  "--stdin"
                  "foo.rb"
                  "--fix"
                  "--stderr"
                ];
              };
              language-servers = [
                { name = "ruby-lsp"; }
              ];
            }
            {
              name = "erb";
              auto-format = true;
              formatter.command = "htmlbeautifier";
              auto-pairs = {
                "<" = ">";
                "%" = "%";
              };
            }
            {
              name = "nix";
              auto-format = true;
              formatter.command = "nixfmt";
              language-servers = [ "nil" ];
            }
          ];
        };
      };
    };
  };
}
