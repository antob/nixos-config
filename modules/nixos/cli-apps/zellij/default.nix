{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.cli-apps.zellij;
in
{
  options.antob.cli-apps.zellij = with types; {
    enable = mkEnableOption "Whether or not to install and configure Zellij.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.file = {
        ".config/zellij/config.kdl".source = ./config.kdl;
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

      # Install plugins
      home.file = {
        # zellij-choose-tree
        ".config/zellij/plugins/zellij-choose-tree.wasm".source = builtins.fetchurl {
          url = "https://github.com/laperlej/zellij-choose-tree/releases/download/v0.4.0/zellij-choose-tree.wasm";
          sha256 = "sha256:1v1xxsqn26y5qrv8726k18wym7ypd1hvdp8j4v6pabbkkhxqdy7i";
        };
      };
    };

    environment.shellAliases = {
      z = "zellij";
    };
  };
}
