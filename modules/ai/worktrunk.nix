{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.worktrunk =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;
    {
      config = {
        home-manager.sharedModules = [ homeManager.worktrunk ];

        environment.systemPackages = with pkgs; [
          worktrunk
        ];

      };
    };

  flake.modules.homeManager.worktrunk =
    { lib, pkgs, ... }:
    {
      xdg.configFile."worktrunk/config.toml".text = /* toml */ ''
        worktree-path = "{{ repo_path }}/../{{ repo }}__worktrees/{{ branch | sanitize }}"
        skip-shell-integration-prompt = true

        [list]
        json-schema = 2

        [pre-start]
        js_deps = "[ -d {{ primary_worktree_path }}/node_modules ] && ln -sf {{ primary_worktree_path }}/node_modules ."
        py_deps = "[ -d {{ primary_worktree_path }}/.venv ] && ln -sf {{ primary_worktree_path }}/.venv ."
        devenv = "[ -d {{ primary_worktree_path }}/.devenv ] && cp {{ primary_worktree_path }}/.envrc . && cp {{ primary_worktree_path }}/.env . && ln -sf {{ primary_worktree_path }}/.devenv . && direnv allow && direnv exec . true"

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

}
