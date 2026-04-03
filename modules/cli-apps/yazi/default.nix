{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.yazi;
  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "9511cb0";
    hash = "sha256-3RR8mi7CcVMDMitdTdaonFmfAIkeOzWK/CVKQmomIhE=";
  };
in
{
  options.antob.cli-apps.yazi = with types; {
    enable = mkEnableOption "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";

        settings = {
          log = {
            enabled = false;
          };
          manager = {
            show_hidden = true;
            sort_dir_first = true;
            scrolloff = 3;
          };
        };

        theme = {
          flavor = {
            dark = "catppuccin-frappe";
            light = "catppuccin-frappe";
          };
        };

        flavors = {
          "catppuccin-frappe" = "${yazi-flavors}/catppuccin-frappe.yazi";
          "catppuccin-latte" = "${yazi-flavors}/catppuccin-latte.yazi";
          "catppuccin-macchiato" = "${yazi-flavors}/catppuccin-macchiato.yazi";
          "catppuccin-mocha" = "${yazi-flavors}/catppuccin-mocha.yazi";
        };

        plugins = {
          "full-border" = pkgs.yaziPlugins.full-border;
        };

        initLua = ''
          require("full-border"):setup()
        '';
      };
    };
  };
}
