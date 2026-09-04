{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.worktrunk;
in
{
  options.antob.cli-apps.worktrunk = {
    enable = mkEnableOption "Whether or not to enable Worktrunk.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      worktrunk
    ];

    antob.home.extraOptions = {
      xdg.configFile."worktrunk/config.toml".text = /* toml */ ''
        worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"
        skip-shell-integration-prompt = true

        [list]
        json-schema = 2

        [aliases]
        ls = "wt list {{ args }}"
        rm = "wt remove {{ args }}"
        move-changes = ''''
        if git diff --quiet HEAD && test -z "$(git ls-files --others --exclude-standard)"; then
          wt switch --create {{ to }} --execute="{{ args }}"
        else
          git stash push --include-untracked --quiet
          wt switch --create {{ to }} --execute="git stash pop --index; {{ args }}"
        fi
        ''''
      '';

      programs.zsh.initContent = ''
        eval "$(${lib.getExe pkgs.worktrunk} config shell init zsh)"
      '';
    };
  };
}
