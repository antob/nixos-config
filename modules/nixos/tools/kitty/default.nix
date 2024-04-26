{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.tools.kitty;
in {
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
        enabled_layouts = "tall,stack";
        hide_window_decorations = "yes";
        background_opacity = "1.0";
      };

      extraConfig = ''
        include ${./themes/one-dark.conf}
      '';

      keybindings = {
        "ctrl+shift+right" = "next_window";
        "ctrl+shift+left" = "previous_window";
        "ctrl+shift+enter" = "new_window_with_cwd";
        "ctrl+shift+tab" = "new_tab_with_cwd";
      };
    };
  };
}
