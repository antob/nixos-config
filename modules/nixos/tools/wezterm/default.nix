{ config, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.tools.wezterm;
in {
  options.antob.tools.wezterm = with types; {
    enable = mkEnableOption "Enable wezterm";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = ''
        return {
          color_scheme = "OneDark (base16)",
          font = wezterm.font "Hack Nerd Font",
          font_size = 12.0,
          window_decorations = "NONE",
        }
      '';
    };
  };
}
