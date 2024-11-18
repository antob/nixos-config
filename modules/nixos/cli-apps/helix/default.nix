{ options, config, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.cli-apps.helix;
in {
  options.antob.cli-apps.helix = with types; {
    enable = mkEnableOption "Whether or not to enable helix.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.helix = {
        enable = true;
        settings = {
          theme = "onedark";

          editor = {
            line-number = "relative";
            mouse = false;
            cursorline = true;
            bufferline = "multiple";
            auto-format = true;
            color-modes = true;
            shell = [ "/usr/bin/zsh" "-c" ];

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
              C-u = [ "half_page_up" "goto_window_center" ];
              C-d = [ "half_page_down" "goto_window_center" ];
              C-g = [ ":new" ":insert-output lazygit" ":buffer-close!" ":redraw" ];
              "A-[" = "goto_previous_buffer";
              "A-]" = "goto_next_buffer";
              A-w = ":buffer-close";
              y = [ ":clipboard-yank" "yank" ];
              X = [ "extend_line_up" "extend_to_line_bounds" ];
              space = {
                c = "file_picker_in_current_buffer_directory";
              };
            };

            insert = { j = { k = "normal_mode"; }; };

            select = {
              y = [ ":clipboard-yank" "yank" ];
              X = [ "extend_line_up" "extend_to_line_bounds" ];
            };
          };
        };

        languages = {
          language-server = {
            solargraph = {
              diagnostics = true;
              formatting = true;
            };
          };

          language = [
            {
              name = "ruby";
              auto-format = true;
              formatter = {
                command = "standardrb";
                args = [ "--stdin" "foo.rb" "--fix" "--stderr" ];
              };
              language-servers = [
                { name = "solargraph"; }
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
            }
          ];
        };
      };
    };
  };
}
