{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.kitty;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.tools.kitty = with types; {
    enable = mkEnableOption "Enable kitty";
    fontSize = mkOpt int 12 "Font size.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.kitty = {
      enable = true;

      environment = {
        TERM = "xterm-256color";
      };

      font = {
        name = "Hack";
        size = cfg.fontSize;
      };

      shellIntegration.enableZshIntegration = true;

      settings = {
        cursor_shape = "beam";
        enable_audio_bell = "no";
        window_padding_width = "4";
        tab_bar_style = "separator";
        tab_separator = " | ";
        enabled_layouts = "tall,vertical,horizontal,grid,stack";
        hide_window_decorations = "yes";
        background_opacity = "1.0";
        window_border_width = "1pt";
        scrollback_lines = 10000;
        term = "xterm-256color";
        clear_all_shortcuts = "yes";
        confirm_os_window_close = 0;
        undercurl_style = "thick-sparse";
        url_color = "#${colors.base06}";
        url_style = "straight";
        # modify_font = "cell_width 103%";
        text_composition_strategy = "legacy"; # Makes font thinner
        allow_remote_control = "socket-only";
        listen_on = "unix:/tmp/kitty.sock";
      };

      extraConfig = ''
        include ${./themes/tokyonight-night.conf}
        active_border_color #${colors.base0C}
        inactive_border_color #${colors.base12}
      '';

      keybindings = {
        "ctrl+shift+equal" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
        "ctrl+shift+0" = "change_font_size all 0";
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        "ctrl+shift+page_up" = "scroll_page_up";
        "ctrl+shift+page_down" = "scroll_page_down";
        "ctrl+shift+z" = "scroll_to_prompt -1";
        "ctrl+shift+x" = "scroll_to_prompt 1";
        "ctrl+shift+f" = "search_scrollback";
        "ctrl+shift+enter" = "launch --cwd=current";
        "ctrl+shift+right" = "next_window";
        "ctrl+shift+left" = "previous_window";
        "ctrl+shift+alt+right" = "move_window_forward";
        "ctrl+shift+alt+left" = "move_window_backward";
        "ctrl+shift+]" = "next_tab";
        "ctrl+shift+[" = "previous_tab";
        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+alt+]" = "move_tab_forward";
        "ctrl+shift+alt+[" = "move_tab_backward";
        "ctrl+shift+4" = "set_tab_title";
        "ctrl+shift+l" = "next_layout";
        "ctrl+shift+p" = "command_palette";
        "ctrl+shift+m" = "toggle_layout stack";
        "ctrl+shift+s" = "goto_session ~/.local/share/kitty/sessions";
        "ctrl+shift+w" =
          "save_as_session --save-only --base-dir ~/.local/share/kitty/sessions --match=session:. .";

        # Browse scrollback buffer in nvim
        "ctrl+shift+h" = "kitty_scrollback_nvim --nvim-args --clean --noplugin -n";
        # Browse output of the last shell command in nvim
        "ctrl+shift+g" =
          "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output --nvim-args --clean --noplugin -n";
      };
      mouseBindings = {
        # Show clicked command output in nvim
        "ctrl+shift+right press" =
          "ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output --nvim-args --clean --noplugin -n";
      };
      actionAliases = {
        # kitty-scrollback.nvim Kitten alias
        "kitty_scrollback_nvim" =
          "kitten '/home/${config.antob.user.name}/.local/share/nvim/site/pack/hm/start/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py'";
      };
    };
  };
}
