{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.direnv;
in
{
  options.antob.tools.direnv = with types; {
    enable = mkBoolOpt false "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {

    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      loadInNixShell = true;
      enableZshIntegration = true;
      direnvrcExtra = /* bash */ ''
        # Work around nix-direnv touching the watched .rc file, which makes
        # every other shell in the directory reload.
        _nix_refresh_gcroots() {
          local layout_dir f
          layout_dir=$(direnv_layout_dir)
          for f in "$layout_dir"/flake-profile-* "$layout_dir"/flake-inputs/* "$layout_dir"/nix-profile-*; do
            [[ -L $f ]] && touch -h "$f"
          done
        }
      '';
    };

    nix.settings = {
      keep-outputs = true;
      keep-derivations = true;
    };

    antob.persistence.home.directories = [ ".local/share/direnv" ];
  };
}
