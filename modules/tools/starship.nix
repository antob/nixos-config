{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.starship =
    { lib, ... }:

    {
      home-manager.sharedModules = [ homeManager.starship ];

    };

  flake.modules.homeManager.starship =
    { lib, ... }:
    {
      programs.starship = {
        enable = true;
        settings = {
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$nix_shell"
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
            truncate_to_repo = false;
          };

          git_status = {
            ahead = "⇡\${count}";
            diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
            behind = "⇣\${count}";
            conflicted = "";
            up_to_date = "";
            untracked = "?";
            modified = "";
            stashed = "";
            staged = "";
            renamed = "";
            deleted = "";
          };

          nix_shell = {
            format = "[$symbol nix]($style) ";
            symbol = "❄";
            style = "bold blue";
          };
        };
      };
    };

}
