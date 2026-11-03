{
  flake.modules.nixos.track-changes =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      options.antob.debug.trackChanges = with types; {
      };

      config = {
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
    };

}
