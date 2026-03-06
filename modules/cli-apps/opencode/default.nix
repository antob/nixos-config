{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.opencode;
in
{
  options.antob.cli-apps.opencode = with types; {
    enable = mkEnableOption "Whether or not to enable opencode.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.opencode = {
        enable = true;
        settings = {
          theme = "tokyonight";
          autoshare = false;
          autoupdate = true;
          permission = {
            # File read permissions
            read = {
              # Environment variables
              "*.env" = "deny";
              "*.env.*" = "deny";
              ".envrc" = "deny";

              # Keys and certificates
              "*.key" = "deny";
              "*.pem" = "deny";
              "*.p12" = "deny";

              # SSH keys
              "id_rsa" = "deny";
              "id_ed25519" = "deny";

              # Cloud service credentials
              ".aws/credentials" = "deny";
              ".gcloud/**" = "deny";

              # Database
              "database.yml" = "ask";

              # Allow examples
              "*.example" = "allow";
              "*.sample" = "allow";
            };

            # File modification permissions
            edit = "ask";

            # Command execution permissions
            bash = {
              "*" = "ask";

              # Git read-only commands
              "git status" = "allow";
              "git diff" = "allow";
              "git log" = "allow";

              # File viewing
              "ls" = "allow";
              "cat" = "allow";
              "pwd" = "allow";

              # Testing and checking
              "npm test" = "allow";
              "npm run lint" = "allow";
              "pytest" = "allow";

              # File deletion
              "rm -rf" = "deny";
              "rm -fr" = "deny";

              # Permission modification
              "chmod 777" = "deny";

              # System-level operations
              "sudo" = "deny";
              "su" = "deny";

              # Disk operations
              "dd" = "deny";

              # Database operations
              "DROP DATABASE" = "deny";
              "TRUNCATE" = "ask";
              "DELETE FROM" = "ask";
            };
          };

          agent = {
            code-reviewer = {
              description = "Reviews code for best practices and potential issues";
              mode = "subagent";
              model = "anthropic/claude-sonnet-4-5";
              prompt = "You are a code reviewer. Focus on security, performance, and maintainability.";
              permission = {
                read = {
                  "*" = "allow";
                };
                edit = "deny";
                bash = "deny";
              };
            };
          };
        };
      };
    };

    antob.persistence = {
      home.directories = [
        ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
        ".cache/opencode"
      ];
    };

    environment.shellAliases = {
      oc = "opencode";
    };
  };
}
