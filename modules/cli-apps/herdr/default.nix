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
      (writeShellScriptBin "herdr-kitty" ''
        ${pkgs.kitty}/bin/kitty --config $HOME/.config/kitty/kitty-no-bindings.conf ${pkgs.herdr}/bin/herdr "$@";
      '')
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
    #     directory = "~/.herdr/worktrees"
    #
    #     [ui]
    #     pane_scrollbars = false
    #     pane_gaps = false
    #     hide_tab_bar_when_single_tab = true
    #     tab_bar_position = "bottom"
    #
    #     [ui.toast]
    #     delivery = "system"
    #
    #     [ui.toast.herdr]
    #     position = "top-right"
    #
    #     [ui.toast.clipboard]
    #     enabled = false
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
