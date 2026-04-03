{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.yazi;
  tokyonight-flavor = pkgs.fetchFromGitHub {
    owner = "BennyOe";
    repo = "tokyo-night.yazi";
    rev = "8e6296f14daff24151c736ebd0b9b6cd89b02b03";
    hash = "sha256-LArhRteD7OQRBguV1n13gb5jkl90sOxShkDzgEf3PA0=";
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
            dark = "tokyo-night";
            light = "tokyo-night";
          };
        };

        flavors = {
          "tokyo-night" = "${tokyonight-flavor}";
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
