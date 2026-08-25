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
      '';

      programs.zsh.initContent = ''
        eval "$(${lib.getExe pkgs.worktrunk} config shell init zsh)"
      '';
    };
  };
}
