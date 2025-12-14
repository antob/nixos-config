{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.walker;
  colors = config.antob.color-scheme.colors;
  wk-launch-webapp = lib.getExe (
    pkgs.callPackage ./scripts/wk-launch-webapp.nix { launchPrefix = cfg.launchPrefix; }
  );
in
{
  options.antob.desktop.addons.walker = with types; {
    enable = mkEnableOption "Whether to enable Walker.";
    runAsService = mkBoolOpt true "Run Walker as a systemd service.";
    launchPrefix = mkOpt types.str "" "Prefix to use to launch apps.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      services.walker = {
        enable = true;
        systemd.enable = cfg.runAsService;
        settings = {
          close_when_open = true;
          force_keyboard_focus = true;
          hotreload_theme = false;
          timeout = 60;
          theme = "custom";

          list = {
            max_entries = 200;
            cycle = true;
          };

          search.placeholder = " Search...";

          builtins = {
            hyprland_keybinds = {
              path = "~/.config/hypr/hyprland.conf";
              hidden = true;
            };

            applications = {
              launch_prefix = cfg.launchPrefix;
              placeholder = " Search...";
              prioritize_new = false;
              context_aware = false;
              show_sub_when_single = false;
              history = false;
              icon = "";
              hidden = false;
              actions = {
                enabled = false;
                hide_category = true;
              };
            };

            calc = {
              name = "Calculator";
              icon = "";
              min_chars = 3;
              prefix = "=";
            };

            windows = {
              switcher_only = true;
              hidden = true;
            };

            clipboard.hidden = true;

            emojis = {
              name = "Emojis";
              icon = "";
              prefix = ":";
            };

            symbols = {
              after_copy = "";
              hidden = true;
            };

            finder = {
              use_fd = true;
              cmd_alt = "xdg-open $(dirname ~/%RESULT%)";
              icon = "file";
              name = "Finder";
              preview_images = true;
              hidden = false;
              prefix = ".";
            };

            runner = {
              shell_config = "";
              switcher_only = true;
              hidden = true;
            };

            ssh = {
              hidden = false;
            };

            websearch = {
              switcher_only = true;
              hidden = true;
            };

            translation = {
              hidden = true;
            };

            custom_commands = {
              hidden = false;
              name = "custom_commands";
              icon = "";
              placeholder = "Custom Commands";

              commands = [
                {
                  name = "Slack";
                  icon = ./icons/slack.png;
                  cmd = "${wk-launch-webapp} https://app.slack.com/client/T029VAUMS";
                }
                {
                  name = "Teams";
                  icon = ./icons/teams.png;
                  cmd = "${wk-launch-webapp} https://teams.microsoft.com";
                }
                {
                  name = "Google Meet";
                  icon = ./icons/meet.png;
                  cmd = "${wk-launch-webapp} https://meet.google.com";
                }
                {
                  name = "Music Assistant";
                  icon = ./icons/music-assistant.png;
                  cmd = "${wk-launch-webapp} https://music.antob.net";
                }
              ];
            };
          };

          ui.window.box = {
            width = 664;
            min_width = 664;
            max_width = 664;
            height = 396;
            min_height = 396;
            max_height = 396;

            # List constraints are critical - without these, the window shrinks when empty
            scroll.list = {
              height = 300;
              min_height = 300;
              max_height = 300;
              item.icon.pixel_size = 40;
            };
          };
        };

        theme = {
          name = "custom";
          style = '''';
        };
      };

      # Custom theme
      xdg.configFile."walker/themes/custom.toml".text = # toml
        ''
          [ui.window.box]
          width = 664
          min_width = 664
          max_width = 664
          height = 396
          min_height = 396
          max_height = 396

          # List constraints are critical - without these, the window shrinks when empty
          [ui.window.box.scroll.list]
          height = 300
          min_height = 300
          max_height = 300

          [ui.window.box.scroll.list.item.icon]
          pixel_size = 40
        '';
      xdg.configFile."walker/themes/custom.css".text = # css
        ''
          @define-color selected-text #${colors.base0C};
          @define-color selected-background #${colors.base10};
          @define-color text #${colors.base06};
          @define-color base #${colors.base01};
          @define-color border #${colors.base0C};
          @define-color foreground #${colors.base06};
          @define-color background #${colors.base01};

          /* Reset all elements */
          #window,
          #box,
          #search,
          #password,
          #input,
          #prompt,
          #clear,
          #typeahead,
          #list,
          child,
          scrollbar,
          slider,
          #item,
          #text,
          #label,
          #sub,
          #activationlabel {
            all: unset;
          }

          * {
            font-family: 'Hack Nerd Font';
            font-size: 18px;
          }

          /* Window */
          #window {
            background: transparent;
            color: @text;
          }

          /* Main box container */
          #box {
            background: alpha(@base, 0.95);
            padding: 20px;
            border: 2px solid @border;
            border-radius: 8px;
          }

          /* Search container */
          #search {
            background: @base;
            padding: 10px;
            margin-bottom: 0;
          }

          /* Hide prompt icon */
          #prompt {
            opacity: 0;
            min-width: 0;
            margin: 0;
          }

          /* Hide clear button */
          #clear {
            opacity: 0;
            min-width: 0;
          }

          /* Input field */
          #input {
            background: none;
            color: @text;
            padding: 0;
          }

          #input placeholder {
            opacity: 0.5;
            color: @text;
          }

          /* Hide typeahead */
          #typeahead {
            opacity: 0;
          }

          /* List */
          #list {
            background: transparent;
          }

          /* List items */
          child {
            padding: 0px 12px;
            background: transparent;
            border-radius: 0;
          }

          child:selected,
          child:hover {
            background-color: @selected-background;
          }

          /* Item layout */
          #item {
            padding: 0;
          }

          #item.active {
            font-style: italic;
          }

          /* Icon */
          #icon {
            margin-right: 10px;
            -gtk-icon-transform: scale(0.7);
          }

          /* Text */
          #text {
            color: @text;
            padding: 14px 0;
          }

          #label {
            font-weight: normal;
          }

          /* Selected state */
          child:selected #text,
          child:selected #label,
          child:hover #text,
          child:hover #label {
            color: @selected-text;
          }

          /* Hide sub text */
          #sub {
            opacity: 0;
            font-size: 0;
            min-height: 0;
          }

          /* Hide activation label */
          #activationlabel {
            opacity: 0;
            min-width: 0;
          }

          /* Scrollbar styling */
          scrollbar {
            opacity: 0;
          }

          /* Hide spinner */
          #spinner {
            opacity: 0;
          }

          /* Hide AI elements */
          #aiScroll,
          #aiList,
          .aiItem {
            opacity: 0;
            min-height: 0;
          }

          /* Bar entry (switcher) */
          #bar {
            opacity: 0;
            min-height: 0;
          }

          .barentry {
            opacity: 0;
          }
        '';

      # Keybindings theme
      xdg.configFile."walker/themes/keybindings.toml".text = ''
        [ui.window.box]
        width = 964
        min_width = 964
        max_width = 964

        height = 664
        min_height = 664
        max_height = 664

        [ui.window.box.search]
        hide = false

        [ui.window.box.scroll]
        v_align = "fill"
        h_align = "fill"
        min_width = 964
        width = 964
        max_width = 964
        min_height = 664
        height = 664
        max_height = 664

        [ui.window.box.scroll.list]
        v_align = "fill"
        h_align = "fill"
        min_width = 900
        width = 900
        max_width = 900
        min_height = 600
        height = 600
        max_height = 600

        [ui.window.box.scroll.list.item]
        h_align = "fill"
        min_width = 900
        width = 900
        max_width = 900

        [ui.window.box.scroll.list.item.activation_label]
        hide = true

        [ui.window.box.scroll.list.placeholder]
        v_align = "start"
        h_align = "fill"
        hide = false
        min_width = 900
        width = 900
        max_width = 900
      '';
      xdg.configFile."walker/themes/keybindings.css".text = ''
        @import url("file://~/.config/walker/themes/custom.css");
      '';

      # Dmenu 250 theme
      xdg.configFile."walker/themes/dmenu_250.toml".text = ''
        [ui.window.box]
        width = 250

        [ui.window.box.scroll.list]
        max_width = 250
        min_width = 250
        width = 250
        max_height = 600

        [ui.window.box.search]
        hide = false
      '';
      xdg.configFile."walker/themes/dmenu_250.css".text = ''
        @import url("file://~/.config/walker/themes/custom.css");
      '';
    };
  };
}
