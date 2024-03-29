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
            };

            insert = { j = { k = "normal_mode"; }; };
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
              formatter.command = "nixpkgs-fmt";
            }
          ];
        };
      };
    };
  };
}
