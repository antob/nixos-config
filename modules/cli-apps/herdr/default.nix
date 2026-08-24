{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.herdr;
in
{
  options.antob.cli-apps.herdr = {
    enable = mkEnableOption "Whether or not to enable Herdr.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      herdr
    ];

    # antob.home.extraOptions = {
    #   xdg.configFile."confil.toml".text = /* toml */ ''
    #     onboarding = false
    #
    #     [theme]
    #     name = "one-dark"
    #
    #     [theme.custom]
    #     accent = "#83a598"
    #
    #     [update]
    #     version_check = false
    #
    #     [worktrees]
    #     directory = "./.worktrees"
    #
    #     [ui]
    #     sidebar_start_collapsed = true
    #     sidebar_collapsed_mode = "hidden"
    #     pane_gaps = false
    #     hide_tab_bar_when_single_tab = true
    #     tab_bar_position = "bottom"
    #
    #     [ui.sound]
    #     enabled = true
    #
    #     [experimental]
    #     kitty_graphics = true
    #     pane_history = false
    #   '';
    # };

    antob.home.extraOptions.programs.zsh.initContent = ''
      eval "$(${lib.getExe pkgs.herdr} completion zsh)"
    '';

    antob.persistence = {
      home.directories = [ ".config/herdr" ];
    };
  };
}
