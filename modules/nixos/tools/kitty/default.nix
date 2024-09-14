{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.tools.kitty;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.tools.kitty = with types; {
    enable = mkEnableOption "Enable kitty";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.kitty = {
      enable = true;

      environment = { TERM = "xterm-256color"; };

      font = {
        name = "Hack Nerd Font";
        size = 14;
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
      };

      extraConfig = ''
        include ${./themes/one-dark.conf}
      '';

      keybindings = {
        "ctrl+shift+right" = "next_window";
        "ctrl+shift+left" = "previous_window";
        "ctrl+shift+enter" = "new_window_with_cwd";
        "ctrl+shift+tab" = "new_tab_with_cwd";
        "ctrl+shift+m" = "toggle_layout stack";
        "ctrl+left" = "resize_window narrower";
        "ctrl+right" = "resize_window wider";
        "ctrl+up" = "resize_window taller";
        "ctrl+down" = "resize_window shorter 3";
        "ctrl+home" = "resize_window reset";
      };
    };
  };
}
