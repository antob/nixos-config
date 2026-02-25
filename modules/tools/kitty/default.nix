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
        name = "Hack Nerd Font";
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
        active_border_color = "#${colors.base0E}";
        inactive_border_color = "#${colors.base08}";
        window_border_width = "1pt";
        scrollback_lines = 10000;
        term = "xterm-256color";
        clear_all_shortcuts = "yes";
        confirm_os_window_close = 0;
        undercurl_style = "thick-sparse";
        url_color = "#${colors.base06}";
        url_style = "straight";
        modify_font = "cell_width 103%";
        text_composition_strategy = "legacy"; # Makes font thinner
      };

      extraConfig = ''
        include ${./themes/tokyonight-night.conf}
      '';

      keybindings = {
        "ctrl+shift+equal" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
        "ctrl+shift+0" = "change_font_size all 0";
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
      };
    };
  };
}
