{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.yazi =
    { lib, ... }:

    {
      home-manager.sharedModules = [ homeManager.yazi ];

    };

  flake.modules.homeManager.yazi =
    { lib, pkgs, ... }:
    {
      stylix.targets.yazi.enable = true;

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

        plugins = {
          "full-border" = pkgs.yaziPlugins.full-border;
        };

        initLua = ''
          require("full-border"):setup()
        '';
      };
    };

}
