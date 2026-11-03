{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.debug.trackChanges;
in
{
  options.antob.debug.trackChanges = with types; {
    enable = mkEnableOption "Track .config changes using git";
  };

  config = mkIf cfg.enable {
    environment.shellInit = ''
      # Add .config to source control (to track changes).
      if [ ! -d "$HOME/.config/.git" ]
      then
          pushd $HOME/.config &> /dev/null
          git init &> /dev/null
          git add . &> /dev/null
          git commit --no-gpg-sign -m 'Initial commit' &> /dev/null
          popd &> /dev/null
      fi
    '';
  };
}
