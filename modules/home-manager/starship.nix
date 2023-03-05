{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.host.tools.starship;
in {
  options.host.tools.starship = with types; {
    enable = mkEnableOption "Whether or not to install and configure starship.";
  };

  config = mkIf cfg.enable {
    # environment.systemPackages = with pkgs; [ starship ];

    programs.starship = {
      enable = true;
      settings = {
        format =
          "$username$hostname$directory$git_branch$git_commit$git_state$git_status$cmd_duration$line_break$battery$status$character";
      };
    };
  };
}
