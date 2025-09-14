{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.starship;
in
{
  options.antob.tools.starship = with types; {
    enable = mkEnableOption "Whether or not to install and configure starship.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.starship = {
        enable = true;
        settings = {
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_commit"
            "$git_state"
            "$git_status"
            "$cmd_duration"
            "$line_break"
            "$battery"
            "$status"
            "$character"
          ];

          add_newline = false;
          scan_timeout = 10;
          command_timeout = 200;
          character = {
            error_symbol = "[✗](bold red)";
            success_symbol = "[❯](bold green)";
          };

          directory = {
            truncation_length = 2;
            truncation_symbol = "…/";
          };

          git_status = {
            ahead = ''⇡''${count}'';
            diverged = ''⇕⇡''${ahead_count}⇣''${behind_count}'';
            behind = ''⇣''${count}'';
            conflicted = "";
            up_to_date = "";
            untracked = "?";
            modified = "";
            stashed = "";
            staged = "";
            renamed = "";
            deleted = "";
          };
        };
      };
    };
  };
}
