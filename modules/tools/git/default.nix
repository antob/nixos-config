{ options, config, pkgs, lib, ... }:

with lib;
let
  cfg = config.antob.tools.git;
  # gpg = config.antob.security.gpg;
  user = config.antob.user;
in {
  options.antob.tools.git = with types; {
    enable = mkEnableOption "Whether or not to install and configure git.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey =
      mkOpt types.str "9762169A1B35EA68" "The key ID to sign commits with.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ git gitui lazygit ];

    antob.home.extraOptions = {
      programs.git = {
        enable = true;
        inherit (cfg) userName userEmail;
        lfs = enabled;

        signing = {
          key = cfg.signingKey;
          # signByDefault = mkIf gpg.enable true;
        };

        aliases.hist =
          "log --graph --pretty=format:'%Cred%h %cd%Creset |%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short";

        extraConfig = {
          init = { defaultBranch = "main"; };
          pull = { rebase = true; };
          push = { autoSetupRemote = true; };
          core = {
            whitespace = "trailing-space,space-before-tab";
            editor = "vim";
            excludesfile = "~/.gitexcludes";
          };
          mergetool = {
            "fugitive".cmd = "nvim -f -c 'Gvdiffsplit!' '$MERGED'";
            keepBackup = false;
            prompt = false;
          };
          merge = {
            tool = "fugitive";
            conflictstyle = "diff3";
          };
        };

        attributes = [
          "*.c     diff=cpp"
          "*.h     diff=cpp"
          "*.c++   diff=cpp"
          "*.h++   diff=cpp"
          "*.cpp   diff=cpp"
          "*.hpp   diff=cpp"
          "*.cc    diff=cpp"
          "*.hh    diff=cpp"
          "*.m     diff=objc"
          "*.mm    diff=objc"
          "*.cs    diff=csharp"
          "*.css   diff=css"
          "*.html  diff=html"
          "*.xhtml diff=html"
          "*.ex    diff=elixir"
          "*.exs   diff=elixir"
          "*.go    diff=golang"
          "*.php   diff=php"
          "*.pl    diff=perl"
          "*.py    diff=python"
          "*.md    diff=markdown"
          "*.rb    diff=ruby"
          "*.rake  diff=ruby"
          "*.rs    diff=rust"
          "*.lisp  diff=lisp"
          "*.el    diff=lisp"
        ];
      };

      home.file = { ".gitexcludes".source = ./.gitexcludes; };
    };
    environment.shellAliases = { gh = "git hist"; };
  };
}
