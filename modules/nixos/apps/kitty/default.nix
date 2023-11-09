{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.apps.kitty;
in {
  options.antob.apps.kitty = with types; {
    enable = mkEnableOption "Enable kitty";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.kitty = {
      enable = true;

      environment = { TERM = "xterm-256color"; };

      font = {
        name = "Hack Nerd Font";
        size = 11.5;
      };

      shellIntegration.enableZshIntegration = true;

      settings = {
        cursor_shape = "beam";
        enable_audio_bell = "no";
        window_padding_width = "4";
        tab_bar_style = "separator";
        tab_separator = " | ";
        enabled_layouts = "tall,stack";
      };

      extraConfig = ''
        include ${./themes/one-dark.conf}
      '';

      # key_bindings = [
      #   {
      #     key = "Tab";
      #     mods = "Control";
      #     chars = "x1b[9;5u";
      #   }
      #   {
      #     key = "Tab";
      #     mods = "Control|Shift";
      #     chars = "x1b[9;6u";
      #   }
      # ];
    };
  };
}
