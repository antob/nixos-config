{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.tools.tofi;
  colors = config.antob.color-scheme.colors;
in
{
  options.antob.tools.tofi = with types; {
    enable = mkEnableOption "Whether or not to install and configure tofi.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.file.".config/tofi/config".text = ''
        font = "${pkgs.antob.sfns-display-font}/share/fonts/truetype/System San Francisco Display Bold.ttf"
        font-size = 11
        font-features = ""
        font-variations = ""
        hint-font = true

        text-color = #${colors.base07}
        prompt-color = #${colors.base0E}
        default-result-color = #${colors.base08}
        selection-color = #${colors.base07}

        text-cursor-style = bar

        prompt-text = ""
        prompt-padding = 10
        result-spacing = 16
        horizontal = true
        min-input-width = 200

        width = 100%
        height = 32
        background-color = #${colors.base10}
        outline-width = 0
        border-width = 0
        clip-to-padding = true
        scale = true

        output = ""
        anchor = top-left
        exclusive-zone = -1

        hide-cursor = false
        text-cursor = true
        history = true
        fuzzy-match = true
        require-match = true
        auto-accept-single = false
        hide-input = false
        hidden-character = "*"
        drun-launch = true
        late-keyboard-init = false
        multi-instance = false
        ascii-input = false
      '';
    };
  };
}
