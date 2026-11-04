{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.zellij =
    {
      config,
      lib,
      ...
    }:

    {
      config = {
        home-manager.sharedModules = [ homeManager.zellij ];

        environment.shellAliases = {
          z = "zellij";
        };

        antob.persistence.home.directories = [ ".cache/zellij" ];
      };
    };

  flake.modules.homeManager.zellij =
    { lib, ... }:
    with lib;
    {
      home.file = {
        ".config/zellij/config.kdl".source = ./_files/config.kdl;
      };

      programs.zellij = {
        enable = true;
        # enableZshIntegration = true;
      };

      # Generate auto completion.
      # Include work around for issue https://github.com/zellij-org/zellij/issues/1933
      programs.zsh.initContent = mkOrder 200 ''
        autoload -U +X compinit && compinit
        . <( zellij setup --generate-completion zsh | sed -Ee 's/^(_(zellij) ).*/compdef \1\2/' )
      '';
    };

}
